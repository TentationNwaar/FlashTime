//
//  MemoryPhoto.swift
//  FlashTime — code partagé entre l'app et le widget
//

import Foundation

/// Une photo « souvenir » : une photo de la photothèque prise le même jour
/// et le même mois qu'aujourd'hui, mais une année antérieure.
nonisolated struct MemoryPhoto: Identifiable, Hashable, Sendable {

    /// `PHAsset.localIdentifier` — permet de recharger l'image à la demande.
    let id: String
    let creationDate: Date
    /// Nombre d'années écoulées depuis la prise de vue (>= 1).
    let yearsAgo: Int

    /// Titre affiché sur le widget : « Il y a 10 ans ».
    var title: String {
        yearsAgo == 1 ? "Il y a 1 an" : "Il y a \(yearsAgo) ans"
    }

    /// Sous-titre : « 4 août 2016 ».
    /// `FormatStyle` plutôt qu'un `DateFormatter` statique : c'est une valeur,
    /// donc utilisable sans risque depuis plusieurs contextes de concurrence.
    var subtitle: String {
        creationDate.formatted(
            .dateTime.day().month(.wide).year().locale(Locale(identifier: "fr_FR"))
        )
    }
}

/// Générateur pseudo-aléatoire déterministe : à graine égale, ordre égal.
/// Permet au widget de mélanger les souvenirs une fois par jour tout en
/// gardant le même ordre entre deux reconstructions de timeline.
nonisolated struct SeededGenerator: RandomNumberGenerator {

    private var state: UInt64

    init(seed: UInt64) {
        // Évite l'état 0, qui bloquerait le générateur.
        self.state = seed &* 6364136223846793005 &+ 1442695040888963407
        if state == 0 { state = 0x9E3779B97F4A7C15 }
    }

    mutating func next() -> UInt64 {
        // SplitMix64
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
