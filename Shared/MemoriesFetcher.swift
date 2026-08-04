//
//  MemoriesFetcher.swift
//  FlashTime — code partagé entre l'app et le widget
//
//  Cœur de l'app : retrouve dans la photothèque les photos prises le même
//  jour/mois qu'aujourd'hui, les années précédentes.
//

import Photos
import UIKit

nonisolated enum MemoriesFetcher {

    // MARK: - Recherche des souvenirs

    /// Retourne les photos prises le même jour et le même mois que `reference`,
    /// une année antérieure. Ne charge aucune image : uniquement des métadonnées,
    /// donc peu coûteux en mémoire (utilisable depuis l'extension widget).
    ///
    /// - Parameters:
    ///   - reference: la date « aujourd'hui » (injectable pour les tests).
    ///   - settings: fenêtre d'années et filtres.
    /// - Returns: souvenirs triés du plus ancien au plus récent.
    static func todaysMemories(
        reference: Date = Date(),
        settings: MemorySettings = .load(),
        calendar: Calendar = .current
    ) -> [MemoryPhoto] {

        let today = calendar.dateComponents([.year, .month, .day], from: reference)
        guard let currentYear = today.year,
              let month = today.month,
              let day = today.day else { return [] }

        // Une plage [00:00, 24:00[ par année ciblée.
        var ranges: [(year: Int, start: Date, end: Date)] = []
        let lowerBound = max(1, settings.minYearsBack)
        let upperBound = max(lowerBound, settings.maxYearsBack)

        for delta in lowerBound...upperBound {
            var components = DateComponents()
            components.year = currentYear - delta
            components.month = month
            components.day = day
            components.hour = 0

            guard let candidate = calendar.date(from: components) else { continue }
            // Le calendrier est « lenient » : un 29 février inexistant devient le
            // 1er mars. On écarte ces dates pour ne pas fausser le libellé.
            let check = calendar.dateComponents([.month, .day], from: candidate)
            guard check.month == month, check.day == day else { continue }

            let start = calendar.startOfDay(for: candidate)
            guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { continue }
            ranges.append((currentYear - delta, start, end))
        }

        guard !ranges.isEmpty else { return [] }

        let predicates = ranges.map {
            NSPredicate(
                format: "creationDate >= %@ AND creationDate < %@",
                $0.start as NSDate,
                $0.end as NSDate
            )
        }

        let options = PHFetchOptions()
        options.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        options.includeAssetSourceTypes = [.typeUserLibrary, .typeCloudShared, .typeiTunesSynced]

        let result = PHAsset.fetchAssets(with: .image, options: options)

        var memories: [MemoryPhoto] = []
        memories.reserveCapacity(result.count)

        result.enumerateObjects { asset, _, _ in
            guard let created = asset.creationDate else { return }

            if settings.excludeScreenshots,
               asset.mediaSubtypes.contains(.photoScreenshot) { return }

            let assetYear = calendar.component(.year, from: created)
            let yearsAgo = currentYear - assetYear
            guard yearsAgo >= 1 else { return }

            memories.append(
                MemoryPhoto(id: asset.localIdentifier, creationDate: created, yearsAgo: yearsAgo)
            )
        }

        return memories
    }

    // MARK: - Chargement d'image

    /// Charge une image redimensionnée pour l'affichage, encodée en JPEG.
    ///
    /// On renvoie du `Data` plutôt qu'une `UIImage` : c'est ce qui transite dans
    /// les entrées de timeline WidgetKit, qui sont sérialisées, et cela garde
    /// l'empreinte mémoire de l'extension (limitée à ~30 Mo) sous contrôle.
    static func imageData(
        for assetID: String,
        targetSize: CGSize,
        contentMode: PHImageContentMode = .aspectFill,
        compression: CGFloat = 0.85
    ) async -> Data? {

        let fetch = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)
        guard let asset = fetch.firstObject else { return nil }
        return await imageData(
            for: asset,
            targetSize: targetSize,
            contentMode: contentMode,
            compression: compression
        )
    }

    static func imageData(
        for asset: PHAsset,
        targetSize: CGSize,
        contentMode: PHImageContentMode = .aspectFill,
        compression: CGFloat = 0.85
    ) async -> Data? {

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true   // photos stockées dans iCloud
        options.isSynchronous = false

        let image: UIImage? = await withCheckedContinuation { continuation in
            var resumed = false
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: contentMode,
                options: options
            ) { image, info in
                // Le handler peut être appelé deux fois (version dégradée puis
                // finale) : on ne reprend la continuation qu'une seule fois.
                let degraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                guard !degraded, !resumed else { return }
                resumed = true
                continuation.resume(returning: image)
            }
        }

        guard let image else { return nil }
        return autoreleasepool { image.jpegData(compressionQuality: compression) }
    }
}
