//
//  SettingsView.swift
//  FlashTime
//

internal import Photos
internal import PhotosUI   // presentLimitedLibraryPicker(from:) est déclaré ici, pas dans Photos
import SwiftUI
import UIKit
import WidgetKit

struct SettingsView: View {

    @State var settings: MemorySettings
    /// Appelé à la fermeture, quelle qu'elle soit (bouton ou balayage) :
    /// les réglages ne sont jamais perdus.
    let onSave: (MemorySettings) -> Void
    let onReplayTutorial: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @ObservedObject private var languageStore = LanguageStore.shared
    @ObservedObject private var premium = PremiumStore.shared
    @ObservedObject private var themeStore = ThemeStore.shared
    @State private var showPremium = false
    @State private var includeVideos = VideoMemories.isEnabled

    @State private var hiddenCount = HiddenPhotos.identifiers.count
    @State private var showPrivacy = false
    @State private var showWidgetHelp = false

    private var accessState: PhotoAccessState { PhotoAccess.current }

    var body: some View {
        ZStack {
            FT.Palette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                FTTopBar(title: L10n.settings) {
                    FTBarButton(title: L10n.done, prominent: true) { dismiss() }
                }

                ScrollView {
                    VStack(spacing: 0) {
                        premiumSection
                        appearanceSection
                        timeWindowSection
                        filtersSection
                        hiddenSection
                        limitedSection
                        languageSection
                        helpSection
                        aboutSection
                    }
                    .frame(maxWidth: 640)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)
            }
            // Un changement de thème reconstruit l'écran avec les nouvelles couleurs.
            .id(themeStore.theme)
        }
        .preferredColorScheme(FT.colorScheme)
        .onDisappear { onSave(settings) }
        .sheet(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showPremium) {
            PremiumView()
        }
        // Résultat de « Restaurer les achats » lancé depuis les réglages.
        .alert(
            premium.notice ?? "",
            isPresented: Binding(
                get: { premium.notice != nil && !showPremium },
                set: { if !$0 { premium.notice = nil } }
            )
        ) {
            Button("OK", role: .cancel) { premium.notice = nil }
        }
    }

    // MARK: - Premium

    private var premiumSection: some View {
        VStack(spacing: 0) {
            FTSectionBanner(title: L10n.premiumName)

            if premium.isPremium {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal")
                        .foregroundStyle(FT.Palette.accent)
                    Text(L10n.premiumActive)
                        .font(FT.Typography.body(15))
                        .foregroundStyle(FT.Palette.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .frame(height: 48)

                divider

                linkRow(L10n.supportTitle, symbol: "cup.and.saucer") { showPremium = true }
            } else {
                footnote(L10n.premiumTagline)
                    .padding(.top, 10)

                Button(L10n.discoverPremium) { showPremium = true }
                    .buttonStyle(.ftOutlineProminent)
                    .padding(.bottom, 28)
            }
        }
    }

    private var appearanceSection: some View {
        VStack(spacing: 0) {
            FTSectionBanner(title: L10n.appearance)

            sublabel(L10n.theme)
            HStack(spacing: 12) {
                ForEach(AppTheme.allCases) { theme in
                    themeSwatch(theme)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 22)

            sublabel(L10n.widgetStyle)
            ForEach(WidgetStyle.allCases) { style in
                let locked = style.isPremium && !premium.isPremium
                Button {
                    if locked { showPremium = true } else { themeStore.select(style) }
                } label: {
                    HStack {
                        Text(style.name)
                            .font(FT.Typography.body(15))
                            .foregroundStyle(FT.Palette.textPrimary)
                        Spacer()
                        if locked {
                            Image(systemName: "lock")
                                .font(.system(size: 12))
                                .foregroundStyle(FT.Palette.textTertiary)
                        } else if themeStore.widgetStyle == style {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13))
                                .foregroundStyle(FT.Palette.accent)
                        }
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 48)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(themeStore.widgetStyle == style ? .isSelected : [])

                divider
            }

            Toggle(isOn: Binding(
                get: { includeVideos && premium.isPremium },
                set: { newValue in
                    guard premium.isPremium else { showPremium = true; return }
                    includeVideos = newValue
                    VideoMemories.setEnabled(newValue)
                }
            )) {
                HStack(spacing: 8) {
                    Text(L10n.includeVideos)
                        .font(FT.Typography.body(15))
                        .foregroundStyle(FT.Palette.textPrimary)
                    if !premium.isPremium {
                        Image(systemName: "lock")
                            .font(.system(size: 12))
                            .foregroundStyle(FT.Palette.textTertiary)
                    }
                }
            }
            .tint(FT.Palette.accent)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .padding(.bottom, 12)
        }
    }

    private func sublabel(_ text: String) -> some View {
        Text(text)
            .font(FT.Typography.sectionLabel(12))
            .tracking(FT.Metric.labelTracking)
            .foregroundStyle(FT.Palette.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 10)
    }

    private func themeSwatch(_ theme: AppTheme) -> some View {
        let colors = theme.colors
        let selected = themeStore.theme == theme
        let locked = theme.isPremium && !premium.isPremium

        return Button {
            if locked { showPremium = true } else { themeStore.select(theme) }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    colors.background
                    VStack(spacing: 4) {
                        Rectangle().fill(colors.surface).frame(height: 8)
                        Rectangle().fill(colors.textPrimary).frame(width: 22, height: 2)
                        Rectangle().fill(colors.accent).frame(width: 14, height: 2)
                    }
                    .padding(6)
                    if locked {
                        Image(systemName: "lock")
                            .font(.system(size: 11))
                            .foregroundStyle(colors.textSecondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                            .padding(5)
                    }
                }
                .frame(height: 54)
                .overlay {
                    Rectangle()
                        .stroke(selected ? FT.Palette.accent : FT.Palette.separator,
                                lineWidth: selected ? 2 : FT.Metric.hairline)
                }
                Text(theme.name)
                    .font(FT.Typography.body(11))
                    .foregroundStyle(selected ? FT.Palette.textPrimary : FT.Palette.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(theme.name)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: - Sections

    private var timeWindowSection: some View {
        VStack(spacing: 0) {
            FTSectionBanner(title: L10n.timeWindow)

            stepperRow(
                label: L10n.from,
                value: L10n.years(settings.minYearsBack),
                canDecrease: settings.minYearsBack > 1,
                canIncrease: settings.minYearsBack < settings.maxYearsBack,
                onDecrease: { settings.minYearsBack -= 1 },
                onIncrease: { settings.minYearsBack += 1 }
            )

            divider

            stepperRow(
                label: L10n.upTo,
                value: L10n.years(settings.maxYearsBack),
                canDecrease: settings.maxYearsBack > settings.minYearsBack,
                canIncrease: settings.maxYearsBack < 50,
                onDecrease: { settings.maxYearsBack -= 1 },
                onIncrease: { settings.maxYearsBack += 1 }
            )

            footnote(L10n.windowFootnote(min: settings.minYearsBack, max: settings.maxYearsBack))
        }
    }

    private var filtersSection: some View {
        VStack(spacing: 0) {
            FTSectionBanner(title: L10n.filters)

            Toggle(isOn: $settings.excludeScreenshots) {
                Text(L10n.excludeScreenshots)
                    .font(FT.Typography.body(15))
                    .foregroundStyle(FT.Palette.textPrimary)
            }
            .tint(FT.Palette.accent)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .padding(.bottom, 12)
        }
    }

    @ViewBuilder
    private var hiddenSection: some View {
        if hiddenCount > 0 {
            FTSectionBanner(title: L10n.hiddenPhotos)

            footnote(L10n.hiddenFootnote(hiddenCount))

            Button(L10n.showAllAgain) {
                HiddenPhotos.clear()
                hiddenCount = 0
                WidgetCenter.shared.reloadAllTimelines()
            }
            .buttonStyle(.ftOutline)
            .padding(.bottom, 28)
        }
    }

    @ViewBuilder
    private var limitedSection: some View {
        if accessState == .limited {
            FTSectionBanner(title: L10n.selection)

            footnote(L10n.limitedFootnote)

            Button(L10n.chooseMorePhotos) {
                presentLimitedPicker()
            }
            .buttonStyle(.ftOutline)
            .padding(.bottom, 28)
        }
    }

    private var languageSection: some View {
        VStack(spacing: 0) {
            FTSectionBanner(title: L10n.language)

            ForEach(AppLanguage.allCases) { language in
                Button {
                    languageStore.select(language)
                } label: {
                    HStack {
                        Text(language.nativeName)
                            .font(FT.Typography.body(15))
                            .foregroundStyle(FT.Palette.textPrimary)
                        Spacer()
                        if language == languageStore.language {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13))
                                .foregroundStyle(FT.Palette.accent)
                        }
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 48)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(language == languageStore.language ? .isSelected : [])

                if language != AppLanguage.allCases.last {
                    divider
                }
            }

            Color.clear.frame(height: 20)
        }
    }

    private var helpSection: some View {
        VStack(spacing: 0) {
            FTSectionBanner(title: L10n.help)

            linkRow(L10n.replayTutorial, symbol: "play.circle") {
                onReplayTutorial()
            }

            divider

            linkRow(L10n.howToAddWidget,
                    symbol: showWidgetHelp ? "chevron.up" : "chevron.down") {
                withAnimation(.easeOut(duration: 0.2)) { showWidgetHelp.toggle() }
            }

            if showWidgetHelp {
                footnote(L10n.coachWidgetBody)
                    .transition(.opacity)
            } else {
                Color.clear.frame(height: 20)
            }
        }
    }

    private var aboutSection: some View {
        VStack(spacing: 0) {
            FTSectionBanner(title: L10n.about)

            linkRow(L10n.privacyPolicy, symbol: "lock.shield") {
                showPrivacy = true
            }

            divider

            linkRow(L10n.restorePurchases, symbol: "arrow.clockwise") {
                Task { await premium.restore() }
            }

            divider

            linkRow(L10n.contactSupport, symbol: "envelope") {
                if let url = supportMailURL { openURL(url) }
            }

            divider

            linkRow(L10n.systemSettings, symbol: "gear") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }

            Text(L10n.version(AppInfo.version, AppInfo.build))
                .font(FT.Typography.body(11))
                .foregroundStyle(FT.Palette.textTertiary)
                .padding(.top, 26)
                .padding(.bottom, 40)
        }
    }

    // MARK: - Lignes

    private func stepperRow(
        label: String,
        value: String,
        canDecrease: Bool,
        canIncrease: Bool,
        onDecrease: @escaping () -> Void,
        onIncrease: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 16) {
            Text(label)
                .font(FT.Typography.body(15))
                .foregroundStyle(FT.Palette.textPrimary)

            Spacer(minLength: 8)

            Text(value)
                .font(FT.Typography.sectionLabel(14))
                .tracking(FT.Metric.labelTracking)
                .foregroundStyle(FT.Palette.textSecondary)
                .monospacedDigit()

            HStack(spacing: 0) {
                stepperButton(symbol: "minus", enabled: canDecrease, action: onDecrease)
                Rectangle()
                    .fill(FT.Palette.separator)
                    .frame(width: FT.Metric.hairline, height: 30)
                stepperButton(symbol: "plus", enabled: canIncrease, action: onIncrease)
            }
            .overlay {
                Rectangle().stroke(FT.Palette.separator, lineWidth: FT.Metric.hairline)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: if canIncrease { onIncrease() }
            case .decrement: if canDecrease { onDecrease() }
            @unknown default: break
            }
        }
    }

    private func stepperButton(symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(enabled ? FT.Palette.textPrimary : FT.Palette.textTertiary)
                .frame(width: 44, height: 34)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func linkRow(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(FT.Typography.body(15))
                    .foregroundStyle(FT.Palette.textPrimary)
                Spacer()
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(FT.Palette.textSecondary)
            }
            .padding(.horizontal, 20)
            .frame(height: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func footnote(_ text: String) -> some View {
        Text(text)
            .font(FT.Typography.body(12))
            .foregroundStyle(FT.Palette.textTertiary)
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 26)
    }

    private var divider: some View {
        Rectangle()
            .fill(FT.Palette.separator)
            .frame(height: FT.Metric.hairline)
            .padding(.leading, 20)
    }

    private var supportMailURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = AppInfo.supportEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: "FlashTime \(AppInfo.version) (\(AppInfo.build))")
        ]
        return components.url
    }

    // MARK: - Accès limité

    private func presentLimitedPicker() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let root = scene.keyWindow?.rootViewController else { return }
        // Le contrôleur présenté (cette feuille) est celui depuis lequel présenter.
        let presenter = root.presentedViewController ?? root
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: presenter)
    }
}

#Preview {
    SettingsView(settings: .default, onSave: { _ in }, onReplayTutorial: {})
}
