//
//  MemoryThumbnail.swift
//  FlashTime
//

import SwiftUI
import UIKit

/// Cache mémoire simple, pour éviter de redemander la même vignette à PhotoKit
/// à chaque réapparition d'une cellule pendant le défilement.
final class ThumbnailCache {

    static let shared = ThumbnailCache()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 300
    }

    func image(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func store(_ image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}

/// Vignette carrée d'un souvenir, chargée paresseusement.
struct MemoryThumbnail: View {

    let memory: MemoryPhoto
    var size: CGFloat = 300

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.secondary.opacity(0.15))

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            }
        }
        .task(id: memory.id) {
            if let cached = ThumbnailCache.shared.image(for: memory.id) {
                image = cached
                return
            }
            let data = await MemoriesFetcher.imageData(
                for: memory.id,
                targetSize: CGSize(width: size, height: size),
                compression: 0.8
            )
            guard let data, let loaded = UIImage(data: data) else { return }
            ThumbnailCache.shared.store(loaded, for: memory.id)
            withAnimation(.easeOut(duration: 0.2)) { image = loaded }
        }
    }
}
