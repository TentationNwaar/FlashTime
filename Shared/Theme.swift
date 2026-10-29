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

    /// Couleurs du thème actif. Le thème anthracite est celui de la version
    /// gratuite ; les autres sont réservés au premium (voir `AppTheme`).
    enum Palette {
        private static var p: AppTheme.Colors { AppTheme.current.colors }

        /// Fond principal.
        static var background: Color { p.background }
        /// Bandeaux de section et surfaces surélevées.
        static var surface: Color { p.surface }
        /// Surface de saisie / cellule.
        static var elevated: Color { p.elevated }
        static var separator: Color { p.separator }
        static var textPrimary: Color { p.textPrimary }
        static var textSecondary: Color { p.textSecondary }
        static var textTertiary: Color { p.textTertiary }
        /// Couleur réservée aux éléments actifs.
        static var accent: Color { p.accent }
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

// MARK: - Thèmes de couleur

nonisolated enum AppTheme: String, CaseIterable, Identifiable, Sendable {

    /// Anthracite neutre : thème d'origine, gratuit.
    case anthracite
    /// Crème clair, façon papier photo.
    case cream
    /// Noir pur, économe sur les écrans OLED.
    case black
    /// Bleu nuit.
    case midnight

    var id: String { rawValue }

    var isPremium: Bool { self != .anthracite }

    var isLight: Bool { self == .cream }

    var name: String {
        switch self {
        case .anthracite: return L10n.tr("Anthracite", "Anthracite", "Antracite", "Anthrazit")
        case .cream: return L10n.tr("Cream", "Crème", "Crema", "Creme")
        case .black: return L10n.tr("Pure black", "Noir pur", "Nero puro", "Tiefschwarz")
        case .midnight: return L10n.tr("Midnight", "Bleu nuit", "Blu notte", "Nachtblau")
        }
    }

    struct Colors: Sendable {
        let background, surface, elevated, separator: Color
        let textPrimary, textSecondary, textTertiary, accent: Color
    }

    private static func rgb(_ hex: UInt32) -> Color {
        Color(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    var colors: Colors {
        let c = AppTheme.rgb
        switch self {
        case .anthracite:
            return Colors(background: c(0x262626), surface: c(0x343434), elevated: c(0x2D2D2D),
                          separator: c(0x454545), textPrimary: c(0xF2F0EC), textSecondary: c(0x9A9996),
                          textTertiary: c(0x6F6F6D), accent: c(0x0770FE))
        case .cream:
            return Colors(background: c(0xF4F0E8), surface: c(0xE9E3D7), elevated: c(0xEDE8DE),
                          separator: c(0xD4CCBE), textPrimary: c(0x1F1D1A), textSecondary: c(0x6B665E),
                          textTertiary: c(0x9A948A), accent: c(0x0763E0))
        case .black:
            return Colors(background: c(0x000000), surface: c(0x121212), elevated: c(0x0B0B0B),
                          separator: c(0x2A2A2A), textPrimary: c(0xF2F0EC), textSecondary: c(0x8E8D8A),
                          textTertiary: c(0x5E5E5C), accent: c(0x0770FE))
        case .midnight:
            return Colors(background: c(0x0F1A2E), surface: c(0x17253F), elevated: c(0x132038),
                          separator: c(0x27395C), textPrimary: c(0xEEF2F8), textSecondary: c(0x93A3BD),
                          textTertiary: c(0x61718B), accent: c(0x4D9BFF))
        }
    }

    private static let key = "premium.theme"

    /// Thème actif. Sans premium, l'app revient toujours à l'anthracite.
    static var current: AppTheme {
        guard PremiumAccess.isUnlocked,
              let raw = AppGroup.defaults.string(forKey: key),
              let theme = AppTheme(rawValue: raw) else { return .anthracite }
        return theme
    }

    static func save(_ theme: AppTheme) {
        AppGroup.defaults.set(theme.rawValue, forKey: key)
    }
}

extension FT {
    /// Apparence système assortie au thème (barre d'état, contrôles natifs).
    static var colorScheme: ColorScheme {
        AppTheme.current.isLight ? .light : .dark
    }
}
