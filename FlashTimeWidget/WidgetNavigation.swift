//
//  WidgetNavigation.swift
//  FlashTimeWidget
//
//  Flèches du widget : passer au souvenir précédent ou suivant du jour sans
//  ouvrir l'app (widgets interactifs, iOS 17+).
//
//  Le toucher d'une flèche exécute `ShowAdjacentMemoryIntent` dans le
//  processus du widget. L'intent décale un compteur stocké dans l'App Group,
//  puis WidgetKit reconstruit automatiquement la timeline, qui tient compte
//  de ce décalage pour choisir la photo affichée.
//

import AppIntents
import Foundation
import WidgetKit

// MARK: - Décalage manuel

nonisolated enum WidgetNavigation {

    private static let offsetKey = "widget.manualOffset"
    private static let dayKey = "widget.manualOffsetDay"

    /// Décalage choisi avec les flèches pour la journée de `date`.
    /// Remis à zéro automatiquement au changement de jour.
    static func offset(for date: Date, calendar: Calendar = .current) -> Int {
        let defaults = AppGroup.defaults
        let day = calendar.startOfDay(for: date).timeIntervalSince1970
        guard defaults.double(forKey: dayKey) == day else { return 0 }
        return defaults.integer(forKey: offsetKey)
    }

    static func move(by step: Int, now: Date = Date(), calendar: Calendar = .current) {
        let defaults = AppGroup.defaults
        let current = offset(for: now, calendar: calendar)
        defaults.set(calendar.startOfDay(for: now).timeIntervalSince1970, forKey: dayKey)
        defaults.set(current + step, forKey: offsetKey)
    }

    /// Modulo toujours positif, y compris pour un décalage négatif.
    static func wrap(_ value: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return ((value % count) + count) % count
    }
}

// MARK: - Intent

struct ShowAdjacentMemoryIntent: AppIntent {

    static let title: LocalizedStringResource = "Show another memory"
    static let isDiscoverable = false

    /// +1 : souvenir suivant, -1 : souvenir précédent.
    @Parameter(title: "Step")
    var step: Int

    init() {
        step = 1
    }

    init(step: Int) {
        self.step = step
    }

    func perform() async throws -> some IntentResult {
        WidgetNavigation.move(by: step)
        return .result()
    }
}
