//
//  AppGroup.swift
//  FlashTime — code partagé entre l'app et le widget
//

import Foundation

/// Identifiants partagés entre la target app et la target widget.
///
/// `nonisolated` : le projet est configuré avec l'isolation MainActor par
/// défaut, or ce code doit rester appelable depuis l'extension widget, dont
/// les points d'entrée ne sont pas isolés.
nonisolated enum AppGroup {

    /// Doit correspondre EXACTEMENT à l'App Group activé sur les deux targets
    /// (Signing & Capabilities > App Groups).
    static let identifier = "group.Maxence-Weyermann.FlashTime"

    /// UserDefaults partagés. Repli sur `.standard` si l'App Group n'est pas
    /// encore configuré, pour que l'app ne crashe pas au lancement.
    static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }

    /// Identifiant du widget, utilisé pour recharger les timelines ciblées.
    static let widgetKind = "FlashTimeWidget"
}

/// Réglages utilisateur, lus par l'app et par le widget.
nonisolated struct MemorySettings: Equatable, Sendable {

    /// Nombre d'années minimum en arrière (1 = l'an dernier).
    var minYearsBack: Int
    /// Nombre d'années maximum en arrière.
    var maxYearsBack: Int
    /// Exclure les captures d'écran des souvenirs.
    var excludeScreenshots: Bool
    /// Exclure les photos marquées « masquées » n'est pas possible via PhotoKit :
    /// les albums masqués ne sont de toute façon pas retournés par la requête.
    var excludeVideosLivePhotoStills: Bool

    static let `default` = MemorySettings(
        minYearsBack: 1,
        maxYearsBack: 30,
        excludeScreenshots: true,
        excludeVideosLivePhotoStills: false
    )

    private enum Key {
        static let min = "settings.minYearsBack"
        static let max = "settings.maxYearsBack"
        static let screenshots = "settings.excludeScreenshots"
        static let stills = "settings.excludeVideosLivePhotoStills"
        static let seeded = "settings.seeded"
    }

    static func load() -> MemorySettings {
        let d = AppGroup.defaults
        guard d.bool(forKey: Key.seeded) else { return .default }
        return MemorySettings(
            minYearsBack: max(1, d.integer(forKey: Key.min)),
            maxYearsBack: max(1, d.integer(forKey: Key.max)),
            excludeScreenshots: d.bool(forKey: Key.screenshots),
            excludeVideosLivePhotoStills: d.bool(forKey: Key.stills)
        )
    }

    func save() {
        let d = AppGroup.defaults
        d.set(true, forKey: Key.seeded)
        d.set(minYearsBack, forKey: Key.min)
        d.set(maxYearsBack, forKey: Key.max)
        d.set(excludeScreenshots, forKey: Key.screenshots)
        d.set(excludeVideosLivePhotoStills, forKey: Key.stills)
    }
}
