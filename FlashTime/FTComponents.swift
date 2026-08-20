//
//  FTComponents.swift
//  FlashTime
//
//  Composants d'interface propres à l'app (le widget n'en a pas l'usage).
//

import SwiftUI

/// Barre supérieure : titre centré en petites capitales, actions textuelles de
/// part et d'autre. Remplace la barre de navigation système, dont le style ne
/// correspond pas à la direction artistique.
struct FTTopBar<Leading: View, Trailing: View>: View {

    let title: String
    @ViewBuilder var leading: Leading
    @ViewBuilder var trailing: Trailing

    var body: some View {
        ZStack {
            Text(title)
                .ftScreenTitle()

            HStack {
                leading
                Spacer(minLength: 0)
                trailing
            }
        }
        .frame(height: 30)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(FT.Palette.background)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(FT.Palette.separator)
                .frame(height: FT.Metric.hairline)
        }
    }
}

extension FTTopBar where Leading == EmptyView {
    init(title: String, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.leading = EmptyView()
        self.trailing = trailing()
    }
}

extension FTTopBar where Leading == EmptyView, Trailing == EmptyView {
    init(title: String) {
        self.title = title
        self.leading = EmptyView()
        self.trailing = EmptyView()
    }
}

/// Action textuelle d'une barre supérieure : « Annuler », « Enregistrer ».
struct FTBarButton: View {

    let title: String
    var prominent: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(FT.Typography.button(12))
                .tracking(FT.Metric.buttonTracking)
                .foregroundStyle(prominent ? FT.Palette.accent : FT.Palette.textSecondary)
        }
        .buttonStyle(.plain)
    }
}

/// Écran d'information plein cadre : symbole filaire, titre éditorial,
/// explication, action facultative. Sert aux états vide, refusé et d'accueil.
struct FTMessageScreen<Action: View>: View {

    let symbol: String
    let title: String
    let message: String
    @ViewBuilder var action: Action

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: symbol)
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundStyle(FT.Palette.textTertiary)
                .padding(.bottom, 28)

            Text(title)
                .font(FT.Typography.display(25))
                .foregroundStyle(FT.Palette.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 12)

            Text(message)
                .font(FT.Typography.body(14))
                .foregroundStyle(FT.Palette.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 44)

            Spacer()

            action
                .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FT.Palette.background)
    }
}

extension FTMessageScreen where Action == EmptyView {
    init(symbol: String, title: String, message: String) {
        self.symbol = symbol
        self.title = title
        self.message = message
        self.action = EmptyView()
    }
}
