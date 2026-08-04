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

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.accessState {
                case .notDetermined:
                    OnboardingView { await viewModel.requestAccess() }
                case .denied:
                    AccessDeniedView()
                case .authorized, .limited:
                    memoriesList
                }
            }
            .navigationTitle("FlashTime")
            .toolbar {
                if viewModel.accessState.canReadLibrary {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                        }
                    }
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
        }
        .task {
            viewModel.refreshAccessState()
            await viewModel.reload()
        }
        .onChange(of: scenePhase) { _, phase in
            // L'utilisateur a pu modifier l'autorisation dans Réglages.
            if phase == .active {
                viewModel.refreshAccessState()
                Task { await viewModel.reload() }
            }
        }
    }

    // MARK: - Liste des souvenirs

    @ViewBuilder
    private var memoriesList: some View {
        if viewModel.isLoading && viewModel.memories.isEmpty {
            ProgressView("Recherche de vos souvenirs…")
        } else if viewModel.memories.isEmpty {
            EmptyMemoriesView(dateLabel: viewModel.todayLabel)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 28, pinnedViews: [.sectionHeaders]) {
                    ForEach(viewModel.groupedByYearsAgo, id: \.yearsAgo) { group in
                        Section {
                            grid(for: group.photos)
                        } header: {
                            sectionHeader(
                                title: group.photos.first?.title ?? "",
                                subtitle: group.photos.first?.subtitle ?? ""
                            )
                        }
                    }
                }
                .padding(.bottom, 32)
            }
            .refreshable { await viewModel.reload() }
        }
    }

    private func grid(for photos: [MemoryPhoto]) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 3),
            spacing: 3
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
        .padding(.horizontal, 3)
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.title3.weight(.semibold))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

// MARK: - Écrans annexes

private struct OnboardingView: View {

    let onRequest: () async -> Void
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "photo.stack")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            VStack(spacing: 10) {
                Text("Vos souvenirs, chaque jour")
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                Text("FlashTime retrouve les photos prises le même jour les années passées et les affiche dans un widget sur votre écran d'accueil.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                isRequesting = true
                Task {
                    await onRequest()
                    isRequesting = false
                }
            } label: {
                Text("Autoriser l'accès aux photos")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isRequesting)
            .padding(.horizontal, 24)

            Text("Les photos ne quittent jamais votre appareil.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.bottom, 24)
        }
    }
}

private struct AccessDeniedView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.circle")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("Accès aux photos refusé")
                .font(.title3.weight(.semibold))
            Text("FlashTime a besoin d'accéder à votre photothèque pour retrouver vos souvenirs. Vous pouvez l'autoriser dans Réglages.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Ouvrir les Réglages") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
        }
    }
}

private struct EmptyMemoriesView: View {

    let dateLabel: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text("Aucun souvenir pour le \(dateLabel)")
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
            Text("Aucune photo de votre photothèque n'a été prise un \(dateLabel) d'une année précédente. Revenez demain.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

#Preview {
    ContentView()
}
