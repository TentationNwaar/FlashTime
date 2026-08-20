//
//  Theme.swift
//  FlashTime — code partagé entre l'app et le widget
//
//  Direction artistique : monochrome anthracite, typographie serif en petites
//  capitales espacées, aucun arrondi superflu. La couleur vient des photos ;
//  le bleu de l'identité n'apparaît que sur les éléments actifs.
//

import SwiftUI

nonisolated enum FT {

    // MARK: - Palette

    enum Palette {
        /// Fond principal, gris neutre sombre plutôt que noir pur.
        static let background = Color(red: 0.149, green: 0.149, blue: 0.149)      // #262626
        /// Bandeaux de section et surfaces surélevées.
        static let surface = Color(red: 0.204, green: 0.204, blue: 0.204)         // #343434
        /// Surface de saisie / cellule.
        static let elevated = Color(red: 0.176, green: 0.176, blue: 0.176)        // #2D2D2D
        static let separator = Color(red: 0.271, green: 0.271, blue: 0.271)       // #454545
        /// Blanc légèrement chaud, moins clinique que le blanc pur.
        static let textPrimary = Color(red: 0.949, green: 0.941, blue: 0.925)     // #F2F0EC
        static let textSecondary = Color(red: 0.604, green: 0.600, blue: 0.588)   // #9A9996
        static let textTertiary = Color(red: 0.435, green: 0.435, blue: 0.427)    // #6F6F6D
        /// Bleu de l'icône, réservé aux éléments actifs.
        static let accent = Color(red: 0.027, green: 0.439, blue: 0.996)          // #0770FE
    }

    // MARK: - Typographie

    enum Typography {

        /// Titre d'écran : « FLASHTIME » en petites capitales très espacées.
        static func screenTitle(_ size: CGFloat = 15) -> Font {
            .system(size: size, weight: .regular, design: .serif).smallCaps()
        }

        /// Libellé de section : « Il y a 10 ans ».
        static func sectionLabel(_ size: CGFloat = 13) -> Font {
            .system(size: size, weight: .regular, design: .serif).smallCaps()
        }

        /// Titre éditorial des écrans d'accueil et d'état vide.
        static func display(_ size: CGFloat = 26) -> Font {
            .system(size: size, weight: .regular, design: .serif)
        }

        /// Libellé de bouton encadré.
        static func button(_ size: CGFloat = 13) -> Font {
            .system(size: size, weight: .medium, design: .serif).smallCaps()
        }

        /// Corps de texte : sans-serif, pour la lisibilité des paragraphes.
        static func body(_ size: CGFloat = 15) -> Font {
            .system(size: size, weight: .regular)
        }
    }

    // MARK: - Métriques

    enum Metric {
        /// Interlettrage des petites capitales, cœur de la DA.
        static let titleTracking: CGFloat = 4
        static let labelTracking: CGFloat = 2.6
        static let buttonTracking: CGFloat = 2.2
        /// Écart entre vignettes de la grille : quasi nul, façon planche contact.
        static let gridSpacing: CGFloat = 2
        static let hairline: CGFloat = 1
    }
}

// MARK: - Modificateurs

extension View {

    /// Titre d'écran centré, petites capitales espacées.
    func ftScreenTitle() -> some View {
        self
            .font(FT.Typography.screenTitle())
            .tracking(FT.Metric.titleTracking)
            .foregroundStyle(FT.Palette.textPrimary)
    }

    /// Libellé de section en petites capitales.
    func ftSectionLabel(secondary: Bool = false) -> some View {
        self
            .font(FT.Typography.sectionLabel())
            .tracking(FT.Metric.labelTracking)
            .foregroundStyle(secondary ? FT.Palette.textSecondary : FT.Palette.textPrimary)
    }

    /// Fond général de l'app.
    func ftBackground() -> some View {
        self.background(FT.Palette.background.ignoresSafeArea())
    }
}

// MARK: - Composants

/// Bandeau de section pleine largeur, texte centré en petites capitales,
/// délimité par un filet fin en haut et en bas.
struct FTSectionBanner: View {

    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: 3) {
            Text(title)
                .ftSectionLabel()
            if let subtitle {
                Text(subtitle)
                    .font(FT.Typography.body(11))
                    .tracking(0.6)
                    .foregroundStyle(FT.Palette.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
            .background(FT.Palette.surface)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(FT.Palette.separator)
                    .frame(height: FT.Metric.hairline)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(FT.Palette.separator)
                    .frame(height: FT.Metric.hairline)
            }
    }
}

/// Bouton encadré d'un filet fin, sans remplissage : l'élément d'action de
/// référence de cette DA.
struct FTOutlineButtonStyle: ButtonStyle {

    /// Un bouton principal reprend le bleu de l'identité sur son filet.
    var prominent: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        let tint = prominent ? FT.Palette.accent : FT.Palette.textPrimary

        return configuration.label
            .font(FT.Typography.button())
            .tracking(FT.Metric.buttonTracking)
            .foregroundStyle(configuration.isPressed ? FT.Palette.background : tint)
            .padding(.vertical, 14)
            .padding(.horizontal, 26)
            .background(configuration.isPressed ? tint : .clear)
            .overlay {
                Rectangle()
                    .stroke(tint, lineWidth: FT.Metric.hairline)
            }
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == FTOutlineButtonStyle {
    static var ftOutline: FTOutlineButtonStyle { FTOutlineButtonStyle() }
    static var ftOutlineProminent: FTOutlineButtonStyle { FTOutlineButtonStyle(prominent: true) }
}
