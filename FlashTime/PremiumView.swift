//
//  PremiumView.swift
//  FlashTime
//
//  Présentation de FlashTime Premium (achat unique) et des pourboires.
//  Exigences Apple respectées : prix affiché tel que fourni par l'App Store,
//  bouton « Restaurer les achats », mention claire qu'il n'y a pas
//  d'abonnement.
//

import StoreKit
import SwiftUI

struct PremiumView: View {

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = PremiumStore.shared
    @ObservedObject private var themeStore = ThemeStore.shared

    var body: some View {
        ZStack {
            FT.Palette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                FTTopBar(title: L10n.premiumName) {
                    FTBarButton(title: L10n.close, prominent: true) { dismiss() }
                }

                ScrollView {
                    VStack(spacing: 0) {
                        header
                        features
                        purchaseBlock
                        tipsBlock

                        Text(L10n.purchaseFootnote)
                            .font(FT.Typography.body(11))
                            .foregroundStyle(FT.Palette.textTertiary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 32)
                            .padding(.top, 8)
                            .padding(.bottom, 40)
                    }
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)
            }
            .id(themeStore.theme)
        }
        .preferredColorScheme(FT.colorScheme)
        .task { await store.load() }
        .alert(
            store.notice ?? "",
            isPresented: Binding(
                get: { store.notice != nil },
                set: { if !$0 { store.notice = nil } }
            )
        ) {
            Button("OK", role: .cancel) { store.notice = nil }
        }
    }

    // MARK: - En-tête

    private var header: some View {
        VStack(spacing: 14) {
            Image("LaunchLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.top, 30)

            Text(L10n.premiumName)
                .font(FT.Typography.display(26))
                .foregroundStyle(FT.Palette.textPrimary)

            Text(L10n.premiumTagline)
                .font(FT.Typography.body(14))
                .foregroundStyle(FT.Palette.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.bottom, 26)
    }

    // MARK: - Fonctions

    private var features: some View {
        VStack(spacing: 0) {
            feature("rectangle.on.rectangle", L10n.featureStylesTitle, L10n.featureStylesBody)
            feature("heart", L10n.featureFavoritesTitle, L10n.featureFavoritesBody)
            feature("paintpalette", L10n.featureThemesTitle, L10n.featureThemesBody)
            feature("play.rectangle", L10n.featureVideosTitle, L10n.featureVideosBody)
        }
        .overlay(alignment: .top) {
            Rectangle().fill(FT.Palette.separator).frame(height: FT.Metric.hairline)
        }
        .padding(.bottom, 28)
    }

    private func feature(_ symbol: String, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(FT.Palette.accent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .ftSectionLabel()
                Text(body)
                    .font(FT.Typography.body(13))
                    .foregroundStyle(FT.Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Rectangle().fill(FT.Palette.separator).frame(height: FT.Metric.hairline)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Achat

    @ViewBuilder
    private var purchaseBlock: some View {
        VStack(spacing: 14) {
            if store.isPremium {
                Label(L10n.premiumActive, systemImage: "checkmark.seal")
                    .font(FT.Typography.body(15))
                    .foregroundStyle(FT.Palette.accent)
            } else if let product = store.premiumProduct {
                Button {
                    Task { await store.purchase(product) }
                } label: {
                    HStack(spacing: 10) {
                        if store.isPurchasing {
                            ProgressView().controlSize(.small).tint(FT.Palette.accent)
                        }
                        Text(L10n.unlockFor(product.displayPrice))
                    }
                    .frame(minWidth: 240)
                }
                .buttonStyle(.ftOutlineProminent)
                .disabled(store.isPurchasing)
            } else if store.loadFailed {
                Text(L10n.storeUnavailable)
                    .font(FT.Typography.body(13))
                    .foregroundStyle(FT.Palette.textTertiary)
            } else {
                ProgressView().tint(FT.Palette.textSecondary)
            }

            if !store.isPremium {
                Button(L10n.restorePurchases) {
                    Task { await store.restore() }
                }
                .font(FT.Typography.body(13))
                .foregroundStyle(FT.Palette.textSecondary)
                .disabled(store.isPurchasing)
            }
        }
        .padding(.bottom, 36)
    }

    // MARK: - Pourboires

    @ViewBuilder
    private var tipsBlock: some View {
        if !store.tipProducts.isEmpty {
            VStack(spacing: 0) {
                FTSectionBanner(title: L10n.supportTitle)

                Text(L10n.supportBody)
                    .font(FT.Typography.body(13))
                    .foregroundStyle(FT.Palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 18)

                HStack(spacing: 10) {
                    ForEach(store.tipProducts, id: \.id) { product in
                        Button {
                            Task { await store.purchase(product) }
                        } label: {
                            VStack(spacing: 4) {
                                Text(tipLabel(for: product.id))
                                    .font(FT.Typography.sectionLabel(12))
                                    .tracking(1.2)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                Text(product.displayPrice)
                                    .font(FT.Typography.body(14))
                            }
                            .foregroundStyle(FT.Palette.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .overlay {
                                Rectangle().stroke(FT.Palette.separator, lineWidth: FT.Metric.hairline)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(store.isPurchasing)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }

    private func tipLabel(for id: String) -> String {
        switch id {
        case ProductID.tipSmall: return L10n.tipSmall
        case ProductID.tipMedium: return L10n.tipMedium
        default: return L10n.tipLarge
        }
    }
}

#Preview {
    PremiumView()
}
