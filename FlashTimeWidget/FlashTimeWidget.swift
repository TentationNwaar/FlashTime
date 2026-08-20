//
//  FlashTimeWidget.swift
//  FlashTimeWidget
//
//  Le widget interroge directement PhotoKit. L'autorisation accordée à l'app
//  conteneur vaut pour son extension : aucune duplication de permission.
//  Seules des métadonnées sont lues, puis une image par entrée de timeline est
//  décodée à la taille exacte du widget, ce qui reste sous la limite mémoire
//  d'environ 30 Mo imposée aux extensions WidgetKit.
//

import SwiftUI
import WidgetKit

// MARK: - Entrée de timeline

nonisolated struct MemoryEntry: TimelineEntry, Sendable {

    enum State: Sendable {
        /// Un souvenir à afficher.
        case memory(MemoryPhoto)
        /// Aucune photo ne correspond à la date du jour.
        case empty
        /// L'accès à la photothèque n'a pas encore été accordé.
        case noAccess
        /// Vue d'attente (galerie de widgets, chargement).
        case placeholder
    }

    let date: Date
    let state: State
    let imageData: Data?
    /// Rang du souvenir dans la sélection du jour, pour l'indicateur « 3/12 ».
    let index: Int
    let total: Int
}

// MARK: - Provider

nonisolated struct MemoryTimelineProvider: TimelineProvider {

    /// Nombre d'entrées générées par timeline. Chaque entrée embarque une image :
    /// on reste volontairement bas pour limiter la taille de la timeline.
    private let entriesPerTimeline = 5
    /// Intervalle entre deux souvenirs.
    private let rotationInterval: TimeInterval = 30 * 60

    func placeholder(in context: Context) -> MemoryEntry {
        MemoryEntry(date: Date(), state: .placeholder, imageData: nil, index: 0, total: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (MemoryEntry) -> Void) {
        // La taille est extraite ici : le contexte n'est pas transmis à la
        // tâche asynchrone, seule une valeur simple l'est.
        let target = targetSize(for: context)
        let fallback = placeholder(in: context)
        Task {
            let entries = await buildEntries(target: target, limit: 1)
            completion(entries.first ?? fallback)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MemoryEntry>) -> Void) {
        let target = targetSize(for: context)
        Task {
            let entries = await buildEntries(target: target, limit: entriesPerTimeline)
            let lastDate = entries.last?.date ?? Date()
            let lastState = entries.last?.state ?? .placeholder
            let reloadDate: Date

            switch lastState {
            case .empty:
                // Rien à montrer aujourd'hui : inutile de consommer le budget de
                // rafraîchissement avant minuit.
                reloadDate = nextMidnight(after: lastDate)
            case .noAccess:
                reloadDate = lastDate.addingTimeInterval(3600)
            case .memory, .placeholder:
                reloadDate = nextReloadDate(after: lastDate)
            }

            completion(Timeline(entries: entries, policy: .after(reloadDate)))
        }
    }

    // MARK: Construction

    private func buildEntries(target: CGSize, limit: Int) async -> [MemoryEntry] {

        let now = Date()

        guard PhotoAccess.current.canReadLibrary else {
            return [MemoryEntry(date: now, state: .noAccess, imageData: nil, index: 0, total: 0)]
        }

        let memories = orderedMemories(for: now)
        guard !memories.isEmpty else {
            return [MemoryEntry(date: now, state: .empty, imageData: nil, index: 0, total: 0)]
        }

        // Décalage courant dans le cycle, pour que la rotation continue d'une
        // reconstruction de timeline à la suivante au lieu de repartir de zéro.
        let calendar = Calendar.current
        let elapsed = now.timeIntervalSince(calendar.startOfDay(for: now))
        let offset = Int(elapsed / rotationInterval) % memories.count

        let count = min(limit, memories.count)

        var entries: [MemoryEntry] = []
        entries.reserveCapacity(count)

        for step in 0..<count {
            let position = (offset + step) % memories.count
            let memory = memories[position]
            let data = await MemoriesFetcher.imageData(
                for: memory.id,
                targetSize: target,
                cropping: .fill,
                compression: 0.8
            )
            entries.append(
                MemoryEntry(
                    date: now.addingTimeInterval(Double(step) * rotationInterval),
                    state: .memory(memory),
                    imageData: data,
                    index: position + 1,
                    total: memories.count
                )
            )
        }

        return entries
    }

    /// Souvenirs du jour, mélangés de façon déterministe : l'ordre est stable
    /// toute la journée, mais différent d'un jour à l'autre.
    private func orderedMemories(for date: Date) -> [MemoryPhoto] {
        let memories = MemoriesFetcher.todaysMemories(reference: date)
        guard memories.count > 1 else { return memories }

        let day = Calendar.current.startOfDay(for: date).timeIntervalSince1970
        var generator = SeededGenerator(seed: UInt64(max(0, day)))
        return memories.shuffled(using: &generator)
    }

    /// Taille de rendu en pixels, dérivée de la taille affichée du widget.
    private func targetSize(for context: Context) -> CGSize {
        let scale: CGFloat = 3
        let display = context.displaySize
        guard display.width > 0, display.height > 0 else {
            return CGSize(width: 600, height: 600)
        }
        return CGSize(width: display.width * scale, height: display.height * scale)
    }

    /// Recharge après la dernière entrée, sans jamais dépasser minuit :
    /// à minuit, les souvenirs du jour changent.
    private func nextReloadDate(after date: Date) -> Date {
        min(date.addingTimeInterval(rotationInterval), nextMidnight(after: date))
    }

    private func nextMidnight(after date: Date) -> Date {
        Calendar.current.startOfDay(for: date.addingTimeInterval(86_400))
    }
}

// MARK: - Déclaration du widget

struct FlashTimeWidget: Widget {

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: AppGroup.widgetKind, provider: MemoryTimelineProvider()) { entry in
            MemoryWidgetView(entry: entry)
        }
        .configurationDisplayName("Souvenirs")
        .description("Les photos prises le même jour, les années passées.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
        .contentMarginsDisabled()
    }
}
