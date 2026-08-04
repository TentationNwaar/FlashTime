//
//  PhotoAccess.swift
//  FlashTime — code partagé entre l'app et le widget
//

import Photos

/// État simplifié de l'autorisation d'accès à la photothèque.
nonisolated enum PhotoAccessState: Sendable {
    /// L'utilisateur n'a pas encore répondu à la demande.
    case notDetermined
    /// Accès complet accordé.
    case authorized
    /// Accès limité : l'utilisateur a choisi une sélection de photos.
    case limited
    /// Refusé ou restreint (contrôle parental, gestion d'appareil).
    case denied

    var canReadLibrary: Bool {
        self == .authorized || self == .limited
    }
}

nonisolated enum PhotoAccess {

    /// Lit le statut courant sans déclencher de demande système.
    static var current: PhotoAccessState {
        map(PHPhotoLibrary.authorizationStatus(for: .readWrite))
    }

    /// Déclenche la demande système (une seule fois par installation).
    @discardableResult
    static func request() async -> PhotoAccessState {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        return map(status)
    }

    private static func map(_ status: PHAuthorizationStatus) -> PhotoAccessState {
        switch status {
        case .notDetermined: return .notDetermined
        case .authorized: return .authorized
        case .limited: return .limited
        case .denied, .restricted: return .denied
        @unknown default: return .denied
        }
    }
}
