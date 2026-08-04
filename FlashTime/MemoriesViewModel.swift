//
//  MemoriesViewModel.swift
//  FlashTime
//

import Combine   // requis explicitement : le projet active MEMBER_IMPORT_VISIBILITY
import Foundation
import Photos
import SwiftUI
import WidgetKit

@MainActor
final class MemoriesViewModel: ObservableObject {

    @Published private(set) var accessState: PhotoAccessState = PhotoAccess.current
    @Published private(set) var memories: [MemoryPhoto] = []
    @Published private(set) var isLoading = false
    @Published var settings: MemorySettings = .load()

    /// Souvenirs regroupés par ancienneté, du plus ancien au plus récent.
    var groupedByYearsAgo: [(yearsAgo: Int, photos: [MemoryPhoto])] {
        Dictionary(grouping: memories, by: \.yearsAgo)
            .map { (yearsAgo: $0.key, photos: $0.value.sorted { $0.creationDate < $1.creationDate }) }
            .sorted { $0.yearsAgo > $1.yearsAgo }
    }

    var todayLabel: String {
        Date().formatted(
            .dateTime.day().month(.wide).locale(Locale(identifier: "fr_FR"))
        )
    }

    // MARK: - Autorisation

    func requestAccess() async {
        accessState = await PhotoAccess.request()
        if accessState.canReadLibrary {
            await reload()
        }
    }

    func refreshAccessState() {
        accessState = PhotoAccess.current
    }

    // MARK: - Chargement

    func reload() async {
        guard accessState.canReadLibrary else {
            memories = []
            return
        }
        isLoading = true
        // La requête ne lit que des métadonnées PhotoKit : assez rapide pour
        // rester sur le MainActor, ce qui évite tout franchissement d'acteur
        // (le projet est configuré avec l'isolation MainActor par défaut).
        memories = MemoriesFetcher.todaysMemories(settings: settings)
        isLoading = false
        WidgetCenter.shared.reloadAllTimelines()
    }

    func applySettings(_ new: MemorySettings) async {
        guard new != settings else { return }
        settings = new
        new.save()
        await reload()
    }
}
