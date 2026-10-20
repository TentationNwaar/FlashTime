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
    /// Vrai dès que la première recherche est terminée : évite d'afficher
    /// « aucun souvenir » pendant une fraction de seconde au démarrage.
    @Published private(set) var hasLoaded = false
    @Published var settings: MemorySettings = .load()

    /// Jour consulté. Par défaut aujourd'hui ; les flèches permettent d'en
    /// parcourir d'autres. Le widget, lui, reste toujours sur aujourd'hui.
    @Published private(set) var referenceDate = Date()

    /// Recherche du jour le plus proche contenant des souvenirs.
    @Published private(set) var isSearchingNearest = false
    @Published private(set) var nearestSearchFailed = false

    /// Photos écartées du widget. L'app continue de les afficher, grisées.
    @Published private(set) var hidden: Set<String> = HiddenPhotos.identifiers

    /// Mode sélection multiple, activé par un appui long sur une vignette.
    @Published var isSelecting = false
    @Published var selection: Set<String> = []

    /// Identifiant de la dernière recherche lancée : une réponse plus ancienne,
    /// arrivée après un changement de jour rapide, est ignorée.
    private var loadToken = UUID()

    // MARK: - Données dérivées

    /// Souvenirs regroupés par ancienneté, du plus ancien au plus récent.
    var groupedByYearsAgo: [(yearsAgo: Int, photos: [MemoryPhoto])] {
        Dictionary(grouping: memories, by: \.yearsAgo)
            .map { (yearsAgo: $0.key, photos: $0.value.sorted { $0.creationDate < $1.creationDate }) }
            .sorted { $0.yearsAgo > $1.yearsAgo }
    }

    /// Ordre d'affichage à plat, identique à celui de la grille : sert au
    /// défilement horizontal de la vue plein écran.
    var orderedMemories: [MemoryPhoto] {
        groupedByYearsAgo.flatMap(\.photos)
    }

    /// Première vignette de la grille, cible des bulles d'aide.
    var firstMemoryID: String? {
        orderedMemories.first?.id
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(referenceDate)
    }

    var dayLabel: String {
        L10n.dayMonth(referenceDate)
    }

    var navigatorLabel: String {
        L10n.navigatorDate(referenceDate)
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
            hasLoaded = true
            return
        }

        let token = UUID()
        loadToken = token
        isLoading = true

        let settings = self.settings
        let reference = referenceDate
        // La requête PhotoKit s'exécute hors du thread principal : sur une
        // grande photothèque, elle ne doit pas figer l'interface.
        let result = await Task.detached(priority: .userInitiated) {
            MemoriesFetcher.todaysMemories(reference: reference, settings: settings)
        }.value

        guard token == loadToken else { return }
        memories = result
        isLoading = false
        hasLoaded = true
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Appelé au retour au premier plan : si l'utilisateur consultait
    /// « aujourd'hui » et que la date a changé entre-temps, on suit.
    func refreshIfDayChanged() async {
        if !Calendar.current.isDateInToday(referenceDate),
           Calendar.current.isDate(referenceDate, inSameDayAs: Date().addingTimeInterval(-86_400)) {
            referenceDate = Date()
        }
        await reload()
    }

    func applySettings(_ new: MemorySettings) async {
        guard new != settings else { return }
        settings = new
        new.save()
        await reload()
    }

    // MARK: - Navigation entre les jours

    func showDay(_ date: Date) {
        referenceDate = date
        nearestSearchFailed = false
        endSelection()
        Task { await reload() }
    }

    func moveDay(by offset: Int) {
        guard let date = Calendar.current.date(byAdding: .day, value: offset, to: referenceDate) else { return }
        showDay(date)
    }

    func showToday() {
        showDay(Date())
    }

    /// Saute au jour le plus proche qui contient des souvenirs.
    func showNearestMemories() async {
        guard !isSearchingNearest else { return }
        isSearchingNearest = true
        nearestSearchFailed = false

        let settings = self.settings
        let reference = referenceDate
        let found = await Task.detached(priority: .userInitiated) {
            MemoriesFetcher.nearestDayWithMemories(from: reference, settings: settings)
        }.value

        isSearchingNearest = false
        if let found {
            showDay(found)
        } else {
            nearestSearchFailed = true
        }
    }

    // MARK: - Photos masquées

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

    func selectAll() {
        selection = Set(memories.map(\.id))
    }

    func endSelection() {
        isSelecting = false
        selection = []
    }

    func applySelection() {
        setHidden(!selectionIsFullyHidden, for: selection)
        endSelection()
    }

    // MARK: - Lien depuis le widget

    /// Retrouve un souvenir d'aujourd'hui à partir de son identifiant, en
    /// revenant d'abord sur la date du jour si nécessaire.
    func memoryForWidgetLink(id: String) async -> MemoryPhoto? {
        if !isToday || !hasLoaded {
            referenceDate = Date()
            endSelection()
            await reload()
        }
        return memories.first { $0.id == id }
    }
}
