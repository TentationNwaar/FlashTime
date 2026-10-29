//
//  MemoryDetailView.swift
//  FlashTime
//

import SwiftUI
import UIKit

/// Affichage plein écran des souvenirs du jour.
///
/// - balayage horizontal : souvenir suivant / précédent ;
/// - balayage vers le bas : fermeture ;
/// - toucher : masque ou réaffiche les commandes ;
/// - barre inférieure : partager, masquer du widget.
struct MemoryDetailView: View {

    let memories: [MemoryPhoto]
    let isHidden: (MemoryPhoto) -> Bool
    let onToggleHidden: (MemoryPhoto) -> Void
    /// Prévient l'écran appelant qu'un favori a changé.
    let onFavoritesChanged: () -> Void

    /// Commandes toujours claires : la vue est sur fond noir, quel que soit
    /// le thème de l'app.
    static let light = Color(red: 0.949, green: 0.941, blue: 0.925)

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var premium = PremiumStore.shared
    @State private var favoriteIDs = FavoritePhotos.identifiers
    @State private var showPremium = false
    @State private var currentID: String
    @State private var showsChrome = true
    @State private var dragOffset: CGFloat = 0
    /// Images déjà chargées, pour le partage de la photo courante.
    @State private var images: [String: UIImage] = [:]
    /// Force le rafraîchissement de l'état « masqué » après un changement.
    @State private var hiddenToggleCount = 0

    init(
        memories: [MemoryPhoto],
        startID: String,
        isHidden: @escaping (MemoryPhoto) -> Bool,
        onToggleHidden: @escaping (MemoryPhoto) -> Void,
        onFavoritesChanged: @escaping () -> Void = {}
    ) {
        self.memories = memories
        self.isHidden = isHidden
        self.onToggleHidden = onToggleHidden
        self.onFavoritesChanged = onFavoritesChanged
        _currentID = State(initialValue: startID)
    }

    private var current: MemoryPhoto? {
        memories.first { $0.id == currentID }
    }

    private var currentIndex: Int {
        memories.firstIndex { $0.id == currentID } ?? 0
    }

    var body: some View {
        ZStack {
            Color.black
                .opacity(1 - min(abs(dragOffset) / 600, 0.6))
                .ignoresSafeArea()

            TabView(selection: $currentID) {
                ForEach(memories) { memory in
                    DetailPage(memory: memory) { image in
                        images[memory.id] = image
                    }
                    .tag(memory.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            .offset(y: dragOffset)
            .onTapGesture {
                withAnimation(.easeOut(duration: 0.2)) { showsChrome.toggle() }
            }
            .simultaneousGesture(dismissGesture)

            if showsChrome {
                chrome
                    .transition(.opacity)
            }
        }
        .statusBarHidden(!showsChrome)
        .sheet(isPresented: $showPremium) { PremiumView() }
        .sensoryFeedback(.selection, trigger: hiddenToggleCount)
    }

    // MARK: - Commandes

    private var chrome: some View {
        VStack(spacing: 0) {
            HStack {
                if memories.count > 1 {
                    Text("\(currentIndex + 1)/\(memories.count)")
                        .font(FT.Typography.body(12).monospacedDigit())
                        .tracking(1)
                        .foregroundStyle(Self.light.opacity(0.75))
                        .padding(.horizontal, 10)
                        .frame(height: 40)
                        .background(.black.opacity(0.25))
                }
                Spacer()
                iconButton("xmark", label: L10n.close) { dismiss() }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Spacer()

            if let current {
                caption(for: current)
                    .padding(.bottom, 18)

                actions(for: current)
                    .padding(.bottom, 28)
            }
        }
        .offset(y: dragOffset)
    }

    private func caption(for memory: MemoryPhoto) -> some View {
        VStack(spacing: 5) {
            Text(memory.title)
                .font(FT.Typography.screenTitle(16))
                .tracking(FT.Metric.titleTracking)
                .foregroundStyle(Self.light)

            Text(memory.subtitle)
                .font(FT.Typography.body(12))
                .foregroundStyle(Self.light.opacity(0.6))
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 34)
        .background(.black.opacity(0.35))
        .overlay {
            Rectangle()
                .stroke(Self.light.opacity(0.25), lineWidth: FT.Metric.hairline)
        }
        .accessibilityElement(children: .combine)
    }

    private func actions(for memory: MemoryPhoto) -> some View {
        // Lecture de hiddenToggleCount : la vue se recalcule après un changement.
        let hidden = hiddenToggleCount >= 0 && isHidden(memory)

        return HStack(spacing: 14) {
            if let image = images[memory.id] {
                let shared = Image(uiImage: image)
                ShareLink(
                    item: shared,
                    preview: SharePreview(memory.title, image: shared)
                ) {
                    iconLabel("square.and.arrow.up")
                }
                // Sans style explicite, iOS ajoute un fond arrondi au ShareLink.
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.share)
            } else {
                iconLabel("square.and.arrow.up")
                    .opacity(0.35)
                    .accessibilityHidden(true)
            }

            let favorite = favoriteIDs.contains(memory.id)
            iconButton(
                favorite ? "heart.fill" : "heart",
                label: favorite ? L10n.removeFavorite : L10n.addFavorite,
                highlighted: favorite
            ) {
                guard premium.isPremium else {
                    showPremium = true
                    return
                }
                FavoritePhotos.toggle(memory.id)
                favoriteIDs = FavoritePhotos.identifiers
                hiddenToggleCount += 1
                onFavoritesChanged()
            }

            iconButton(
                hidden ? "eye.slash" : "eye",
                label: hidden ? L10n.showInWidget : L10n.hideFromWidget,
                highlighted: hidden
            ) {
                onToggleHidden(memory)
                hiddenToggleCount += 1
            }
        }
    }

    private func iconButton(
        _ symbol: String,
        label: String,
        highlighted: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            iconLabel(symbol, highlighted: highlighted)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func iconLabel(_ symbol: String, highlighted: Bool = false) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 15, weight: .light))
            .foregroundStyle(highlighted ? FT.Palette.accent : Self.light)
            .frame(width: 44, height: 44)
            .background(.black.opacity(0.25))
            .overlay {
                Rectangle()
                    .stroke(Self.light.opacity(0.35), lineWidth: FT.Metric.hairline)
            }
    }

    // MARK: - Fermeture par balayage

    private var dismissGesture: some Gesture {
        DragGesture(minimumDistance: 24)
            .onChanged { value in
                // On ne réagit qu'aux gestes nettement verticaux, pour ne pas
                // gêner le défilement horizontal entre les photos.
                let t = value.translation
                guard abs(t.height) > abs(t.width) * 1.4, t.height > 0 else { return }
                dragOffset = t.height
            }
            .onEnded { value in
                if dragOffset > 140 || value.predictedEndTranslation.height > 400 {
                    dismiss()
                } else {
                    withAnimation(.spring(duration: 0.3)) { dragOffset = 0 }
                }
            }
    }
}

// MARK: - Page

/// Une photo, chargée à la demande quand la page devient visible.
private struct DetailPage: View {

    let memory: MemoryPhoto
    let onLoad: (UIImage) -> Void

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Color.clear

            if memory.kind == .video, PremiumAccess.isUnlocked {
                MemoryVideoView(memory: memory)
            } else if memory.kind == .livePhoto, PremiumAccess.isUnlocked {
                // L'image fixe s'affiche d'abord ; la Live Photo la remplace dès
                // qu'elle est chargée (appui long pour la lire).
                ZStack {
                    if let image {
                        Image(uiImage: image).resizable().scaledToFit()
                    }
                    MemoryLivePhotoView(memory: memory)
                }
            } else if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .transition(.opacity)
            } else {
                ProgressView()
                    .tint(MemoryDetailView.light.opacity(0.6))
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(memory.title), \(memory.subtitle)")
        .accessibilityAddTraits(.isImage)
        .task(id: memory.id) {
            guard image == nil, memory.kind != .video else { return }
            // Taille généreuse : PhotoKit renvoie au plus la taille réelle de la
            // photo, donc on ne gaspille rien sur les images plus petites.
            let target = CGSize(width: 2400, height: 2400)
            let data = await MemoriesFetcher.imageData(
                for: memory.id,
                targetSize: target,
                cropping: .fit,
                compression: 0.9
            )
            guard let data, let loaded = UIImage(data: data) else { return }
            withAnimation(.easeOut(duration: 0.3)) { image = loaded }
            onLoad(loaded)
        }
    }
}
