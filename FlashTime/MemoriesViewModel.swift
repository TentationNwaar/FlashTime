//
//  MemoriesViewModel.swift
//  FlashTime
//

import Combine   // requis explicitement : le projet active MEMBER_IMPORT_VISIBILITY
import Foundation
import SwiftUI
import WidgetKit

@MainActor
final class MemoriesViewModel: ObservableObject {

    @Published private(set) var accessState: PhotoAccessState = PhotoAccess.current
    @Published private(set) var memories: [MemoryPhoto] = []
    @Published private(set) var isLoading = false
    @Published var settings: MemorySettings = .load()

    /// Photos écartées du widget. L'app continue de les afficher, grisées.
    @Published private(set) var hidden: Set<String> = HiddenPhotos.identifiers

    /// Mode sélection multiple, activé par un appui long sur une vignette.
    @Published var isSelecting = false
    @Published var selection: Set<String> = []

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

    // MARK: - Photos masquées

    var visibleCount: Int {
        memories.count - memories.filter { hidden.contains($0.id) }.count
    }

    func isHidden(_ memory: MemoryPhoto) -> Bool {
        hidden.contains(memory.id)
    }

    /// Relit le stockage partagé : les réglages peuvent l'avoir vidé.
    func refreshHidden() {
        hidden = HiddenPhotos.identifiers
    }

    func setHidden(_ shouldHide: Bool, for ids: Set<String>) {
        guard !ids.isEmpty else { return }
        HiddenPhotos.setHidden(shouldHide, for: ids)
        hidden = HiddenPhotos.identifiers
        WidgetCenter.shared.reloadAllTimelines()
    }

    func toggleHidden(_ memory: MemoryPhoto) {
        setHidden(!isHidden(memory), for: [memory.id])
    }

    func showAll() {
        HiddenPhotos.clear()
        hidden = []
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Sélection

    /// Vrai si toutes les photos sélectionnées sont déjà masquées : l'action
    /// proposée devient alors « réafficher ».
    var selectionIsFullyHidden: Bool {
        !selection.isEmpty && selection.allSatisfy { hidden.contains($0) }
    }

    func beginSelection(with memory: MemoryPhoto) {
        isSelecting = true
        selection = [memory.id]
    }

    func toggleSelection(_ memory: MemoryPhoto) {
        if selection.contains(memory.id) {
            selection.remove(memory.id)
        } else {
            selection.insert(memory.id)
        }
    }

    func endSelection() {
        isSelecting = false
        selection = []
    }

    func applySelection() {
        setHidden(!selectionIsFullyHidden, for: selection)
        endSelection()
    }
}
