//
//  ContentView.swift
//  FlashTime
//
//  Created by Maxence Weyermann on 04.08.2026.
//

import SwiftUI
import UIKit

struct ContentView: View {

    @StateObject private var viewModel = MemoriesViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSettings = false
    @State private var selected: MemoryPhoto?
    @State private var showLaunch = true

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
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(settings: viewModel.settings) { new in
                Task { await viewModel.applySettings(new) }
            }
        }
        .fullScreenCover(item: $selected) { memory in
            MemoryDetailView(memory: memory)
        }
        .onChange(of: scenePhase) { _, phase in
            // L'utilisateur a pu modifier l'autorisation dans Réglages.
            // La garde évite un second chargement pendant l'écran de démarrage,
            // qui effectue déjà le premier.
            if phase == .active, !showLaunch {
                viewModel.refreshAccessState()
                Task { await viewModel.reload() }
            }
        }
    }

    // MARK: - Structure

    private var mainContent: some View {
        ZStack {
            FT.Palette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                FTTopBar(title: "FlashTime") {
                    if viewModel.accessState.canReadLibrary {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 15, weight: .light))
                                .foregroundStyle(FT.Palette.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                switch viewModel.accessState {
                case .notDetermined:
                    onboarding
                case .denied:
                    accessDenied
                case .authorized, .limited:
                    memoriesList
                }
            }
        }
    }

    // MARK: - Liste des souvenirs

    @ViewBuilder
    private var memoriesList: some View {
        if viewModel.isLoading && viewModel.memories.isEmpty {
            VStack {
                Spacer()
                Text("Recherche en cours")
                    .ftSectionLabel(secondary: true)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FT.Palette.background)
        } else if viewModel.memories.isEmpty {
            FTMessageScreen(
                symbol: "calendar",
                title: "Aucun souvenir\nle \(viewModel.todayLabel)",
                message: "Votre photothèque ne contient aucune photo prise ce jour-là une année précédente. Revenez demain."
            )
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
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(FT.Palette.background)
            .refreshable { await viewModel.reload() }
        }
    }

    private func grid(for photos: [MemoryPhoto]) -> some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(), spacing: FT.Metric.gridSpacing),
                count: 3
            ),
            spacing: FT.Metric.gridSpacing
        ) {
            ForEach(photos) { photo in
                Button {
                    selected = photo
                } label: {
                    MemoryThumbnail(memory: photo)
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, FT.Metric.gridSpacing)
        .padding(.top, FT.Metric.gridSpacing)
    }

    // MARK: - États d'accès

    private var onboarding: some View {
        FTMessageScreen(
            symbol: "photo.on.rectangle.angled",
            title: "Vos souvenirs,\nchaque jour",
            message: "FlashTime retrouve les photos prises le même jour les années passées et les affiche dans un widget sur votre écran d'accueil. Elles ne quittent jamais votre appareil."
        ) {
            Button("Autoriser l'accès aux photos") {
                Task { await viewModel.requestAccess() }
            }
            .buttonStyle(.ftOutlineProminent)
        }
    }

    private var accessDenied: some View {
        FTMessageScreen(
            symbol: "lock",
            title: "Accès refusé",
            message: "FlashTime a besoin de lire les dates de vos photos pour retrouver vos souvenirs. L'autorisation se règle dans les réglages du système."
        ) {
            Button("Ouvrir les réglages") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.ftOutline)
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
