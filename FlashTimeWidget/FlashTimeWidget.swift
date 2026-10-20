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
            let plan = await buildTimeline(target: target, limit: 1, includeTomorrow: false)
            completion(plan.entries.first ?? fallback)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MemoryEntry>) -> Void) {
        let target = targetSize(for: context)
        Task {
            let plan = await buildTimeline(target: target, limit: entriesPerTimeline)
            completion(Timeline(entries: plan.entries, policy: .after(plan.reloadDate)))
        }
    }

    // MARK: Construction

    private struct TimelinePlan {
        let entries: [MemoryEntry]
        let reloadDate: Date
    }

    private func buildTimeline(
        target: CGSize,
        limit: Int,
        includeTomorrow: Bool = true
    ) async -> TimelinePlan {

        let now = Date()
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: now.addingTimeInterval(86_400))

        guard PhotoAccess.current.canReadLibrary else {
            return TimelinePlan(
                entries: [MemoryEntry(date: now, state: .noAccess, imageData: nil, index: 0, total: 0)],
                reloadDate: now.addingTimeInterval(3600)
            )
        }

        var entries: [MemoryEntry] = []
        // Par défaut : reconstruction juste après le changement de date.
        var reloadDate = midnight.addingTimeInterval(120)

        // MARK: Journée en cours
        let memories = orderedMemories(for: now)

        if memories.isEmpty {
            entries.append(MemoryEntry(date: now, state: .empty, imageData: nil, index: 0, total: 0))
        } else {
            // Décalage courant dans le cycle, pour que la rotation continue d'une
            // reconstruction de timeline à la suivante au lieu de repartir de zéro.
            let elapsed = now.timeIntervalSince(calendar.startOfDay(for: now))
            // Le décalage choisi avec les flèches du widget s'ajoute à la
            // rotation automatique.
            let offset = WidgetNavigation.wrap(
                Int(elapsed / rotationInterval) + WidgetNavigation.offset(for: now),
                count: memories.count
            )
            let count = min(limit, memories.count)

            for step in 0..<count {
                let date = now.addingTimeInterval(Double(step) * rotationInterval)
                // Aucune entrée ne franchit minuit : au-delà, les souvenirs et
                // leur libellé « il y a X ans » ne sont plus valables.
                guard step == 0 || date < midnight else { break }

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
                        date: date,
                        state: .memory(memory),
                        imageData: data,
                        index: position + 1,
                        total: memories.count
                    )
                )
            }

            // Rechargement dès que la dernière entrée du jour a été servie, afin
            // de poursuivre la rotation. Jamais au-delà du changement de date.
            let lastDate = entries.last?.date ?? now
            reloadDate = min(
                lastDate.addingTimeInterval(rotationInterval),
                midnight.addingTimeInterval(120)
            )
        }

        // MARK: Bascule automatique du jour
        //
        // On planifie dès maintenant le premier souvenir de demain, daté de
        // minuit. Le widget change donc de photo au changement de date même si
        // iOS ne réveille pas l'extension à cet instant précis — ce qui est le
        // cas ordinaire la nuit. Sans cette entrée, l'affichage resterait figé
        // sur la veille jusqu'au prochain réveil du système.
        if includeTomorrow {
            let tomorrow = orderedMemories(for: midnight)

            if let first = tomorrow.first {
                let data = await MemoriesFetcher.imageData(
                    for: first.id,
                    targetSize: target,
                    cropping: .fill,
                    compression: 0.8
                )
                entries.append(
                    MemoryEntry(
                        date: midnight,
                        state: .memory(first),
                        imageData: data,
                        index: 1,
                        total: tomorrow.count
                    )
                )
            } else {
                entries.append(
                    MemoryEntry(date: midnight, state: .empty, imageData: nil, index: 0, total: 0)
                )
            }
        }

        return TimelinePlan(entries: entries, reloadDate: reloadDate)
    }

    /// Souvenirs du jour, mélangés de façon déterministe : l'ordre est stable
    /// toute la journée, mais différent d'un jour à l'autre. Les photos écartées
    /// par l'utilisateur sont retirées ici.
    private func orderedMemories(for date: Date) -> [MemoryPhoto] {
        let hidden = HiddenPhotos.identifiers
        let memories = MemoriesFetcher.todaysMemories(reference: date)
            .filter { !hidden.contains($0.id) }
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
}

// MARK: - Déclaration du widget

struct FlashTimeWidget: Widget {

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: AppGroup.widgetKind, provider: MemoryTimelineProvider()) { entry in
            MemoryWidgetView(entry: entry)
        }
        .configurationDisplayName(L10n.widgetName)
        .description(L10n.widgetDescription)
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
        .contentMarginsDisabled()
    }
}
