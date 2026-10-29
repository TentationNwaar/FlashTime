//
//  MediaViews.swift
//  FlashTime
//
//  Lecture des vidéos et des Live Photos (fonctions premium). Ce fichier
//  n'est compilé que pour l'app : le widget reste strictement photo.
//

import AVFoundation
import AVKit
internal import Photos
internal import PhotosUI
import SwiftUI
import UIKit

// MARK: - Vidéo

/// Lecteur vidéo plein écran pour un souvenir. La vidéo est demandée à
/// PhotoKit (téléchargée depuis iCloud si nécessaire) puis lue en boucle,
/// son coupé par défaut comme dans l'app Photos.
struct MemoryVideoView: View {

    let memory: MemoryPhoto

    @State private var player: AVPlayer?
    @State private var failed = false

    var body: some View {
        ZStack {
            if let player {
                VideoPlayer(player: player)
                    .onAppear { player.play() }
                    .onDisappear { player.pause() }
            } else if failed {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 28, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.6))
            } else {
                ProgressView().tint(.white)
            }
        }
        .task(id: memory.id) {
            guard player == nil else { return }
            if let item = await MediaLoader.playerItem(for: memory.id) {
                let player = AVPlayer(playerItem: item)
                player.isMuted = true
                self.player = player
            } else {
                failed = true
            }
        }
    }
}

// MARK: - Live Photo

/// Live Photo animée : un appui long la lit, comme dans l'app Photos.
struct MemoryLivePhotoView: UIViewRepresentable {

    let memory: MemoryPhoto

    func makeUIView(context: Context) -> PHLivePhotoView {
        let view = PHLivePhotoView()
        view.contentMode = .scaleAspectFit
        view.backgroundColor = .clear
        context.coordinator.load(memory.id, into: view)
        return view
    }

    func updateUIView(_ uiView: PHLivePhotoView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        func load(_ id: String, into view: PHLivePhotoView) {
            let scale = UIScreen.main.scale
            let target = CGSize(width: UIScreen.main.bounds.width * scale,
                                height: UIScreen.main.bounds.height * scale)
            Task { @MainActor [weak view] in
                guard let livePhoto = await MediaLoader.livePhoto(for: id, targetSize: target) else { return }
                view?.livePhoto = livePhoto
                // Courte lecture d'aperçu, pour signaler que la photo est animée.
                view?.startPlayback(with: .hint)
            }
        }
    }
}

// MARK: - Chargement

/// `nonisolated` : les rappels de PhotoKit arrivent sur des files quelconques,
/// ils ne doivent pas hériter de l'isolation MainActor par défaut du projet.
nonisolated enum MediaLoader {

    static func livePhoto(for id: String, targetSize: CGSize) async -> PHLivePhoto? {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject else {
            return nil
        }
        let options = PHLivePhotoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        return await withCheckedContinuation { continuation in
            var resumed = false
            PHImageManager.default().requestLivePhoto(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { livePhoto, info in
                // Le rappel peut arriver deux fois (aperçu dégradé, puis final).
                let degraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                guard !degraded, !resumed else { return }
                resumed = true
                continuation.resume(returning: livePhoto)
            }
        }
    }

    static func playerItem(for id: String) async -> AVPlayerItem? {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject else {
            return nil
        }
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .automatic

        return await withCheckedContinuation { continuation in
            PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { item, _ in
                continuation.resume(returning: item)
            }
        }
    }
}
