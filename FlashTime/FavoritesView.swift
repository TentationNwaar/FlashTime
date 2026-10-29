//
//  FavoritesView.swift
//  FlashTime
//
//  Section « Favoris » (premium) : tous les souvenirs marqués d'un cœur,
//  quelle que soit leur date, regroupés par année de prise de vue.
//

import Foundation
import SwiftUI

struct FavoritesView: View {

    let isHidden: (MemoryPhoto) -> Bool
    let onToggleHidden: (MemoryPhoto) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @ObservedObject private var themeStore = ThemeStore.shared

    @State private var favorites: [MemoryPhoto] = []
    @State private var loaded = false
    @State private var viewerStartID: String?

    /// Regroupement par année de prise de vue, de la plus récente à la plus ancienne.
    private var groups: [(year: Int, photos: [MemoryPhoto])] {
        Dictionary(grouping: favorites) { Calendar.current.component(.year, from: $0.creationDate) }
            .map { (year: $0.key, photos: $0.value.sorted { $0.creationDate > $1.creationDate }) }
            .sorted { $0.year > $1.year }
    }

    var body: some View {
        ZStack {
            FT.Palette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                FTTopBar(title: L10n.favorites) {
                    FTBarButton(title: L10n.done, prominent: true) { dismiss() }
                }

                if !loaded {
                    Spacer()
                    ProgressView().tint(FT.Palette.textSecondary)
                    Spacer()
                } else if favorites.isEmpty {
                    FTMessageScreen(
                        symbol: "heart",
                        title: L10n.noFavoritesTitle,
                        message: L10n.noFavoritesBody
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                            ForEach(groups, id: \.year) { group in
                                Section {
                                    grid(group.photos)
                                        .padding(.bottom, 26)
                                } header: {
                                    FTSectionBanner(
                                        title: String(group.year),
                                        subtitle: L10n.photosCount(group.photos.count)
                                    )
                                }
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .id(themeStore.theme)
        }
        .preferredColorScheme(FT.colorScheme)
        .task { await load() }
        .fullScreenCover(
            item: Binding(
                get: { viewerStartID.map { FavoriteViewerRequest(id: $0) } },
                set: { viewerStartID = $0?.id }
            ),
            onDismiss: { Task { await load() } }
        ) { request in
            MemoryDetailView(
                memories: favorites,
                startID: request.id,
                isHidden: isHidden,
                onToggleHidden: onToggleHidden
            )
        }
    }

    private func grid(_ photos: [MemoryPhoto]) -> some View {
        LazyVGrid(
            columns: [GridItem(
                .adaptive(minimum: sizeClass == .regular ? 200 : 104,
                          maximum: sizeClass == .regular ? 320 : 220),
                spacing: FT.Metric.gridSpacing
            )],
            spacing: FT.Metric.gridSpacing
        ) {
            ForEach(photos) { photo in
                Button {
                    viewerStartID = photo.id
                } label: {
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                        .overlay { MemoryThumbnail(memory: photo) }
                        .clipped()
                        .overlay(alignment: .bottomLeading) { MediaBadge(memory: photo) }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(photo.subtitle)")
                .contextMenu {
                    Button {
                        FavoritePhotos.toggle(photo.id)
                        Task { await load() }
                    } label: {
                        Label(L10n.removeFavorite, systemImage: "heart.slash")
                    }
                }
            }
        }
        .padding(.horizontal, FT.Metric.gridSpacing)
        .padding(.top, FT.Metric.gridSpacing)
    }

    private func load() async {
        let ids = FavoritePhotos.identifiers
        let result = await Task.detached(priority: .userInitiated) {
            MemoriesFetcher.favoriteMemories(ids: ids)
        }.value
        favorites = result
        loaded = true
    }
}

private struct FavoriteViewerRequest: Identifiable {
    let id: String
}

/// Badge discret sur les vignettes : durée des vidéos, mention « LIVE ».
struct MediaBadge: View {

    let memory: MemoryPhoto

    var body: some View {
        switch memory.kind {
        case .video:
            HStack(spacing: 3) {
                Image(systemName: "play.fill").font(.system(size: 8))
                Text(memory.durationText).font(.system(size: 10, weight: .medium).monospacedDigit())
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            .background(.black.opacity(0.45))
            .padding(5)
        case .livePhoto:
            if PremiumAccess.isUnlocked {
                Text("LIVE")
                    .font(.system(size: 8, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(.black.opacity(0.45))
                    .padding(5)
            }
        case .photo:
            EmptyView()
        }
    }
}
