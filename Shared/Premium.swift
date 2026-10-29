//
//  Premium.swift
//  FlashTime — code partagé entre l'app et le widget
//
//  État de la version premium et réglages qui en dépendent. Tout est stocké
//  dans l'App Group : le widget lit les mêmes valeurs que l'app.
//
//  L'achat lui-même est vérifié par StoreKit dans l'app (PremiumStore), qui
//  recopie ici le résultat. Le widget ne parle jamais à StoreKit.
//

import Foundation

// MARK: - Accès premium

nonisolated enum PremiumAccess {

    private static let key = "premium.unlocked"

    static var isUnlocked: Bool {
        AppGroup.defaults.bool(forKey: key)
    }

    static func setUnlocked(_ unlocked: Bool) {
        AppGroup.defaults.set(unlocked, forKey: key)
    }
}

// MARK: - Styles de widget

nonisolated enum WidgetStyle: String, CaseIterable, Identifiable, Sendable {
    /// Photo pleine, légende sur dégradé (style gratuit).
    case classic
    /// Photo encadrée de blanc, légende dessous, façon tirage instantané.
    case polaroid
    /// Photo seule, sans aucun texte.
    case photoOnly
    /// Photo pleine avec un filet blanc intérieur et légende centrée.
    case hairline

    var id: String { rawValue }

    var isPremium: Bool { self != .classic }

    var name: String {
        switch self {
        case .classic: return L10n.tr("Classic", "Classique", "Classico", "Klassisch")
        case .polaroid: return L10n.tr("Instant print", "Tirage instantané", "Stampa istantanea", "Sofortbild")
        case .photoOnly: return L10n.tr("Photo only", "Photo seule", "Solo foto", "Nur Foto")
        case .hairline: return L10n.tr("Fine frame", "Filet fin", "Cornice sottile", "Feiner Rahmen")
        }
    }

    private static let key = "premium.widgetStyle"

    /// Style choisi. Sans premium, le widget revient toujours au style classique.
    static var current: WidgetStyle {
        guard PremiumAccess.isUnlocked,
              let raw = AppGroup.defaults.string(forKey: key),
              let style = WidgetStyle(rawValue: raw) else { return .classic }
        return style
    }

    static func save(_ style: WidgetStyle) {
        AppGroup.defaults.set(style.rawValue, forKey: key)
    }
}

// MARK: - Photos favorites

/// Souvenirs marqués d'un cœur. Le widget les montre deux fois plus souvent,
/// et l'app les rassemble dans une section dédiée.
nonisolated enum FavoritePhotos {

    private static let key = "premium.favoriteIdentifiers"

    static var identifiers: Set<String> {
        Set(AppGroup.defaults.stringArray(forKey: key) ?? [])
    }

    static func isFavorite(_ id: String) -> Bool {
        identifiers.contains(id)
    }

    static func toggle(_ id: String) {
        var current = identifiers
        if current.contains(id) {
            current.remove(id)
        } else {
            current.insert(id)
        }
        AppGroup.defaults.set(Array(current), forKey: key)
    }

    static func remove(_ ids: Set<String>) {
        AppGroup.defaults.set(Array(identifiers.subtracting(ids)), forKey: key)
    }
}

// MARK: - Vidéos

nonisolated enum VideoMemories {

    private static let key = "premium.includeVideos"

    /// Inclure les vidéos du jour dans l'app (jamais dans le widget).
    /// Activé par défaut dès que le premium est acheté.
    static var isEnabled: Bool {
        guard PremiumAccess.isUnlocked else { return false }
        return AppGroup.defaults.object(forKey: key) as? Bool ?? true
    }

    static func setEnabled(_ enabled: Bool) {
        AppGroup.defaults.set(enabled, forKey: key)
    }
}
