//
//  ContentView.swift
//  FlashTime
//
//  Created by Maxence Weyermann on 04.08.2026.
//

import StoreKit
import SwiftUI
import UIKit

/// Demande d'ouverture de la vue plein écran.
private struct ViewerRequest: Identifiable {
    /// Souvenir affiché en premier.
    let id: String
    let memories: [MemoryPhoto]
}

struct ContentView: View {

    @StateObject private var viewModel = MemoriesViewModel()
    @StateObject private var coach = CoachMarks()
    @ObservedObject private var languageStore = LanguageStore.shared
    @ObservedObject private var premium = PremiumStore.shared
    @ObservedObject private var themeStore = ThemeStore.shared

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.requestReview) private var requestReview
    @Environment(\.horizontalSizeClass) private var sizeClass

    /// Tutoriel d'accueil terminé. Remis à faux pour le rejouer.
    @AppStorage("onboarding.completed") private var introCompleted = false
    @State private var introIncludesLanguage = true

    @State private var showLaunch = true
    @State private var showSettings = false
    @State private var showDatePicker = false
    @State private var replayAfterSettings = false
    @State private var viewer: ViewerRequest?
    @State private var showPremium = false
    @State private var showFavorites = false
    /// Les bulles n'apparaissent qu'une fois l'écran stabilisé.
    @State private var coachReady = false

    /// Durée minimale d'affichage du logo, pour que le fondu ne soit pas coupé
    /// net quand la recherche des souvenirs est immédiate.
    private let minimumLaunchDuration: TimeInterval = 1.1

    var body: some View {
        ZStack {
            mainContent

            if showLaunch {
                LaunchOverlayView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .environment(\.locale, languageStore.language.locale)
        .preferredColorScheme(FT.colorScheme)
        .task {
            // Droits d'achat : vérifiés à chaque lancement auprès de StoreKit.
            await premium.load()
        }
        .onChange(of: premium.isPremium) { _, _ in
            viewModel.refreshFavorites()
            Task { await viewModel.reload() }
        }
        .sheet(isPresented: $showPremium) {
            PremiumView()
                .environment(\.locale, languageStore.language.locale)
        }
        .sheet(isPresented: $showFavorites, onDismiss: { viewModel.refreshFavorites() }) {
            FavoritesView(
                isHidden: { viewModel.isHidden($0) },
                onToggleHidden: { viewModel.toggleHidden($0) }
            )
            .environment(\.locale, languageStore.language.locale)
        }
        .task {
            viewModel.refreshAccessState()

            let start = Date()
            await viewModel.reload()

            let elapsed = Date().timeIntervalSince(start)
            if elapsed < minimumLaunchDuration {
                try? await Task.sleep(for: .seconds(minimumLaunchDuration - elapsed))
            }

            withAnimation(.easeInOut(duration: 0.5)) {
                showLaunch = false
            }
            registerUsageDay()
            try? await Task.sleep(for: .seconds(0.6))
            coachReady = true
        }
        .sheet(isPresented: $showSettings, onDismiss: settingsDismissed) {
            SettingsView(
                settings: viewModel.settings,
                onSave: { new in
                    Task { await viewModel.applySettings(new) }
                },
                onReplayTutorial: {
                    replayAfterSettings = true
                    showSettings = false
                }
            )
            .environment(\.locale, languageStore.language.locale)
        }
        .sheet(isPresented: $showDatePicker) {
            datePickerSheet
        }
        .fullScreenCover(item: $viewer) { request in
            MemoryDetailView(
                memories: request.memories,
                startID: request.id,
                isHidden: { viewModel.isHidden($0) },
                onToggleHidden: { viewModel.toggleHidden($0) },
                onFavoritesChanged: { viewModel.refreshFavorites() }
            )
        }
        .onChange(of: scenePhase) { _, phase in
            // L'utilisateur a pu modifier l'autorisation dans Réglages, ou la
            // date a pu changer. La garde évite un second chargement pendant
            // l'écran de démarrage, qui effectue déjà le premier.
            if phase == .active, !showLaunch {
                viewModel.refreshAccessState()
                Task { await viewModel.refreshIfDayChanged() }
                registerUsageDay()
            }
        }
        .onOpenURL { url in
            openFromWidget(url)
        }
    }

    // MARK: - Structure

    private var mainContent: some View {
        ZStack {
            FT.Palette.background.ignoresSafeArea()

            if !introCompleted {
                OnboardingView(includesLanguage: introIncludesLanguage) {
                    finishIntro()
                }
                .transition(.opacity)
            } else {
                VStack(spacing: 0) {
                    topBar

                    switch viewModel.accessState {
                    case .notDetermined:
                        accessRequest
                    case .denied:
                        accessDenied
                    case .authorized, .limited:
                        dayNavigator
                        memoriesList
                    }
                }
                .overlay(alignment: .bottom) {
                    if viewModel.isSelecting {
                        selectionBar
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                // Un changement de thème reconstruit l'écran avec les nouvelles couleurs.
                .id(themeStore.theme)
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: viewModel.isSelecting)
        .animation(.easeInOut(duration: 0.35), value: introCompleted)
        .sensoryFeedback(.selection, trigger: viewModel.selection)
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.hidden)
        .overlayPreferenceValue(CoachAnchorKey.self) { anchors in
            coachOverlay(anchors)
        }
    }

    // MARK: - Bulles d'aide

    private var coachEnabled: Bool {
        coachReady
            && introCompleted
            && !showLaunch
            && viewModel.accessState.canReadLibrary
            && viewModel.hasLoaded
            && !viewModel.isLoading
            && !viewModel.isSelecting
            && !showSettings
            && !showDatePicker
            && viewer == nil
    }

    @ViewBuilder
    private func coachOverlay(_ anchors: [CoachTarget: Anchor<CGRect>]) -> some View {
        let pending = coachEnabled ? coach.pending(available: Set(anchors.keys)) : []

        if let step = pending.first {
            CoachMarkOverlay(
                step: step,
                anchor: step.target.flatMap { anchors[$0] },
                index: coach.seen.count + 1,
                total: coach.seen.count + pending.count,
                onNext: {
                    withAnimation(.easeOut(duration: 0.2)) { coach.markSeen(step) }
                },
                onSkip: {
                    withAnimation(.easeOut(duration: 0.2)) { coach.skipAll() }
                }
            )
            .id(step)
            .transition(.opacity)
        }
    }

    // MARK: - Barres

    @ViewBuilder
    private var topBar: some View {
        if viewModel.isSelecting {
            FTTopBar(title: selectionTitle) {
                FTBarButton(title: L10n.selectAll) {
                    viewModel.selectAll()
                }
            } trailing: {
                FTBarButton(title: L10n.done, prominent: true) {
                    viewModel.endSelection()
                }
            }
        } else {
            FTTopBar(title: L10n.appName) {
                if viewModel.accessState.canReadLibrary, !viewModel.isToday {
                    FTBarButton(title: L10n.today) {
                        viewModel.showToday()
                    }
                }
            } trailing: {
                if viewModel.accessState.canReadLibrary {
                    Button {
                        if premium.isPremium { showFavorites = true } else { showPremium = true }
                    } label: {
                        Image(systemName: "heart")
                            .font(.system(size: 15, weight: .light))
                            .foregroundStyle(FT.Palette.textSecondary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.favorites)

                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 15, weight: .light))
                            .foregroundStyle(FT.Palette.textSecondary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, -12)
                    .accessibilityLabel(L10n.settings)
                    .coachTarget(.settingsButton)
                }
            }
        }
    }

    private var selectionTitle: String {
        viewModel.selection.isEmpty ? L10n.selection : L10n.photosCount(viewModel.selection.count)
    }

    private var selectionBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(FT.Palette.separator)
                .frame(height: FT.Metric.hairline)

            Button {
                viewModel.applySelection()
            } label: {
                Text(viewModel.selectionIsFullyHidden ? L10n.showInWidget : L10n.hideFromWidget)
            }
            .buttonStyle(.ftOutline)
            .disabled(viewModel.selection.isEmpty)
            .opacity(viewModel.selection.isEmpty ? 0.4 : 1)
            .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity)
        .background(FT.Palette.background)
    }

    // MARK: - Navigation entre les jours

    private var dayNavigator: some View {
        HStack(spacing: 0) {
            navigatorArrow("chevron.left", label: L10n.previousDay) {
                viewModel.moveDay(by: -1)
            }

            Button {
                showDatePicker = true
            } label: {
                VStack(spacing: 2) {
                    Text(viewModel.navigatorLabel)
                        .ftSectionLabel()
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text(navigatorSubtitle)
                        .font(FT.Typography.body(11))
                        .foregroundStyle(FT.Palette.textTertiary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(viewModel.navigatorLabel)
            .accessibilityValue(navigatorSubtitle)
            .accessibilityHint(L10n.chooseDate)

            navigatorArrow("chevron.right", label: L10n.nextDay) {
                viewModel.moveDay(by: 1)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(FT.Palette.background)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(FT.Palette.separator)
                .frame(height: FT.Metric.hairline)
        }
        .coachTarget(.dayNavigator)
        .disabled(viewModel.isSelecting)
        .opacity(viewModel.isSelecting ? 0.4 : 1)
    }

    private var navigatorSubtitle: String {
        if viewModel.isLoading || !viewModel.hasLoaded { return L10n.searching }
        return viewModel.memories.isEmpty ? "—" : L10n.memoriesCount(viewModel.memories.count)
    }

    private func navigatorArrow(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(FT.Palette.textSecondary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var datePickerSheet: some View {
        VStack(spacing: 0) {
            FTTopBar(title: L10n.chooseDate) {
                FTBarButton(title: L10n.today) {
                    viewModel.showToday()
                    showDatePicker = false
                }
            } trailing: {
                FTBarButton(title: L10n.done, prominent: true) {
                    showDatePicker = false
                }
            }

            DatePicker(
                L10n.chooseDate,
                selection: Binding(
                    get: { viewModel.referenceDate },
                    set: { viewModel.showDay($0) }
                ),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            .tint(FT.Palette.accent)
            .padding(.horizontal, 16)

            Spacer(minLength: 0)
        }
        .background(FT.Palette.background.ignoresSafeArea())
        .environment(\.locale, languageStore.language.locale)
        .preferredColorScheme(FT.colorScheme)
        .presentationDetents([.height(520), .large])
    }

    // MARK: - Liste des souvenirs

    @ViewBuilder
    private var memoriesList: some View {
        if !viewModel.hasLoaded || (viewModel.isLoading && viewModel.memories.isEmpty) {
            VStack {
                Spacer()
                ProgressView()
                    .tint(FT.Palette.textSecondary)
                    .padding(.bottom, 12)
                Text(L10n.searching)
                    .ftSectionLabel(secondary: true)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FT.Palette.background)
        } else if viewModel.memories.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    ForEach(viewModel.groupedByYearsAgo, id: \.yearsAgo) { group in
                        Section {
                            grid(for: group.photos)
                                .padding(.bottom, 26)
                        } header: {
                            FTSectionBanner(
                                title: group.photos.first?.title ?? "",
                                subtitle: group.photos.first?.subtitle
                            )
                            .accessibilityAddTraits(.isHeader)
                        }
                    }
                }
                // Dégage la barre d'actions de sélection.
                .padding(.bottom, viewModel.isSelecting ? 92 : 24)
            }
            .scrollIndicators(.hidden)
            .background(FT.Palette.background)
            .refreshable { await viewModel.reload() }
            .opacity(viewModel.isLoading ? 0.6 : 1)
            .animation(.easeOut(duration: 0.15), value: viewModel.isLoading)
        }
    }

    private var emptyState: some View {
        FTMessageScreen(
            symbol: "calendar",
            title: L10n.noMemoriesTitle(viewModel.dayLabel),
            message: viewModel.nearestSearchFailed ? L10n.nothingNearby : L10n.noMemoriesMessage
        ) {
            Button {
                Task { await viewModel.showNearestMemories() }
            } label: {
                HStack(spacing: 10) {
                    if viewModel.isSearchingNearest {
                        ProgressView()
                            .controlSize(.small)
                            .tint(FT.Palette.textPrimary)
                    }
                    Text(L10n.showNearest)
                }
            }
            .buttonStyle(.ftOutline)
            .disabled(viewModel.isSearchingNearest)
        }
    }

    private func grid(for photos: [MemoryPhoto]) -> some View {
        LazyVGrid(
            // Colonnes adaptatives : 3 sur iPhone, 4 à 5 sur iPad.
            columns: [GridItem(
                .adaptive(minimum: sizeClass == .regular ? 200 : 104,
                          maximum: sizeClass == .regular ? 320 : 220),
                spacing: FT.Metric.gridSpacing
            )],
            spacing: FT.Metric.gridSpacing
        ) {
            ForEach(photos) { photo in
                if viewModel.isSelecting {
                    cell(photo)
                } else {
                    cell(photo)
                        .contextMenu {
                            contextActions(for: photo)
                        }
                }
            }
        }
        .padding(.horizontal, FT.Metric.gridSpacing)
        .padding(.top, FT.Metric.gridSpacing)
    }

    private func cell(_ photo: MemoryPhoto) -> some View {
        Button {
            if viewModel.isSelecting {
                viewModel.toggleSelection(photo)
            } else {
                viewer = ViewerRequest(id: photo.id, memories: viewModel.orderedMemories)
            }
        } label: {
            thumbnail(photo)
        }
        .buttonStyle(.plain)
        .coachTarget(.firstPhoto, active: photo.id == viewModel.firstMemoryID)
        .accessibilityLabel(accessibilityLabel(for: photo))
        .accessibilityAddTraits(viewModel.selection.contains(photo.id) ? [.isImage, .isSelected] : .isImage)
    }

    private func accessibilityLabel(for photo: MemoryPhoto) -> String {
        var parts = [photo.title, photo.subtitle]
        if photo.isVideo { parts.append(photo.durationText) }
        if viewModel.isFavorite(photo) { parts.append(L10n.favorites) }
        if viewModel.isHidden(photo) { parts.append(L10n.hiddenFromWidget) }
        return parts.joined(separator: ", ")
    }

    private func thumbnail(_ photo: MemoryPhoto) -> some View {
        let isHidden = viewModel.isHidden(photo)
        let isSelected = viewModel.selection.contains(photo.id)

        return Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                MemoryThumbnail(memory: photo)
            }
            .clipped()
            .contentShape(Rectangle())
            // Une photo écartée reste visible dans l'app, mais assourdie.
            .opacity(isHidden ? 0.32 : 1)
            .overlay(alignment: .topTrailing) {
                if isHidden {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 10, weight: .light))
                        .foregroundStyle(.white)
                        .padding(5)
                        .background(.black.opacity(0.45))
                        .padding(5)
                }
            }
            .overlay(alignment: .topLeading) {
                if viewModel.isFavorite(photo) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.6), radius: 2)
                        .padding(6)
                }
            }
            .overlay(alignment: .bottomLeading) {
                MediaBadge(memory: photo)
            }
            .overlay {
                if viewModel.isSelecting {
                    Rectangle()
                        .stroke(isSelected ? FT.Palette.accent : .clear, lineWidth: 2)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if viewModel.isSelecting {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(isSelected ? FT.Palette.accent : Color.white.opacity(0.8))
                        .shadow(color: .black.opacity(0.5), radius: 2)
                        .padding(6)
                }
            }
    }

    @ViewBuilder
    private func contextActions(for photo: MemoryPhoto) -> some View {
        Button {
            if !viewModel.toggleFavorite(photo) { showPremium = true }
        } label: {
            Label(
                viewModel.isFavorite(photo) ? L10n.removeFavorite : L10n.addFavorite,
                systemImage: viewModel.isFavorite(photo) ? "heart.slash" : (premium.isPremium ? "heart" : "lock")
            )
        }

        Button {
            viewModel.toggleHidden(photo)
        } label: {
            Label(
                viewModel.isHidden(photo) ? L10n.showInWidget : L10n.hideFromWidget,
                systemImage: viewModel.isHidden(photo) ? "eye" : "eye.slash"
            )
        }

        Button {
            viewModel.beginSelection(with: photo)
        } label: {
            Label(L10n.selectSeveral, systemImage: "checkmark.circle")
        }
    }

    // MARK: - États d'accès

    private var accessRequest: some View {
        FTMessageScreen(
            symbol: "photo.on.rectangle.angled",
            title: L10n.welcomeTitle,
            message: L10n.accessMessage
        ) {
            // Libellé neutre (« Continuer ») : la demande système suit
            // immédiatement, conformément aux règles de l'App Store.
            Button(L10n.continueLabel) {
                Task { await viewModel.requestAccess() }
            }
            .buttonStyle(.ftOutlineProminent)
        }
    }

    private var accessDenied: some View {
        FTMessageScreen(
            symbol: "lock",
            title: L10n.deniedTitle,
            message: L10n.deniedMessage
        ) {
            Button(L10n.openSettings) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.ftOutline)
        }
    }

    // MARK: - Actions

    private func finishIntro() {
        coachReady = false
        introCompleted = true
        // Laisse l'écran principal se mettre en place avant la première bulle.
        Task {
            try? await Task.sleep(for: .seconds(0.8))
            coachReady = true
        }
    }

    private func settingsDismissed() {
        viewModel.refreshHidden()
        viewModel.refreshFavorites()
        // L'option « vidéos du jour » a pu changer.
        Task { await viewModel.reload() }
        if replayAfterSettings {
            replayAfterSettings = false
            coach.reset()
            introIncludesLanguage = false
            introCompleted = false
        }
    }

    /// Lien `flashtime://memory?id=…` envoyé par le widget : ouvre la photo.
    private func openFromWidget(_ url: URL) {
        guard url.scheme == "flashtime", url.host == "memory",
              let id = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "id" })?.value,
              introCompleted else { return }

        showSettings = false
        showDatePicker = false
        Task {
            if let memory = await viewModel.memoryForWidgetLink(id: id) {
                viewer = ViewerRequest(id: memory.id, memories: viewModel.orderedMemories)
            }
        }
    }

    /// Compte les jours d'utilisation distincts. Au quatrième, si des souvenirs
    /// sont affichés, iOS est invité à proposer une note — une seule fois.
    /// Le système décide lui-même d'afficher ou non la demande.
    private func registerUsageDay() {
        let defaults = UserDefaults.standard
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let today = "\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"

        var days = defaults.stringArray(forKey: "usage.days") ?? []
        if !days.contains(today) {
            days.append(today)
            defaults.set(Array(days.suffix(10)), forKey: "usage.days")
        }

        guard days.count >= 4,
              !defaults.bool(forKey: "review.requested"),
              introCompleted,
              !viewModel.memories.isEmpty else { return }

        defaults.set(true, forKey: "review.requested")
        Task {
            try? await Task.sleep(for: .seconds(2))
            requestReview()
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
