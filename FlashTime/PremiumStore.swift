//
//  PremiumStore.swift
//  FlashTime
//
//  Achats intégrés avec StoreKit 2 :
//  - « FlashTime Premium » : achat unique (non consommable), 2,99 € ;
//  - trois pourboires (consommables), sans contrepartie.
//
//  Le paiement est entièrement géré par Apple. L'app ne reçoit que la preuve
//  d'achat signée, vérifiée ici, puis recopie « premium débloqué » dans
//  l'App Group pour que le widget en tienne compte.
//
//  Les identifiants de produits ci-dessous doivent être créés à l'identique
//  dans App Store Connect (voir PUBLICATION.md).
//

import Combine
import Foundation
import StoreKit
import WidgetKit

nonisolated enum ProductID {
    static let premium = "flashtime.premium.unlock"
    static let tipSmall = "flashtime.tip.small"
    static let tipMedium = "flashtime.tip.medium"
    static let tipLarge = "flashtime.tip.large"

    static let tips = [tipSmall, tipMedium, tipLarge]
    static let all = [premium] + tips
}

@MainActor
final class PremiumStore: ObservableObject {

    static let shared = PremiumStore()

    @Published private(set) var isPremium: Bool = PremiumAccess.isUnlocked
    @Published private(set) var premiumProduct: Product?
    @Published private(set) var tipProducts: [Product] = []
    @Published private(set) var isPurchasing = false
    @Published private(set) var loadFailed = false
    /// Message affiché après un pourboire ou une restauration.
    @Published var notice: String?

    private var updatesTask: Task<Void, Never>?

    private init() {
        // Écoute les transactions arrivées hors de l'app : achat approuvé plus
        // tard (contrôle parental), achat sur un autre appareil, remboursement.
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }
    }

    // MARK: - Chargement

    func load() async {
        loadFailed = false
        do {
            let products = try await Product.products(for: ProductID.all)
            premiumProduct = products.first { $0.id == ProductID.premium }
            tipProducts = products
                .filter { ProductID.tips.contains($0.id) }
                .sorted { $0.price < $1.price }
            loadFailed = premiumProduct == nil
        } catch {
            loadFailed = true
        }
        await refreshEntitlements()
    }

    /// Relit les droits en cours : source de vérité pour le premium.
    func refreshEntitlements() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == ProductID.premium,
               transaction.revocationDate == nil {
                unlocked = true
            }
        }
        setPremium(unlocked)
    }

    // MARK: - Achat

    func purchase(_ product: Product) async {
        guard !isPurchasing else { return }
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                await handle(verification)
                if ProductID.tips.contains(product.id) {
                    notice = L10n.tipThanks
                }
            case .pending, .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            notice = L10n.purchaseFailed
        }
    }

    /// « Restaurer les achats » : obligatoire pour un achat non consommable.
    func restore() async {
        isPurchasing = true
        defer { isPurchasing = false }
        try? await AppStore.sync()
        await refreshEntitlements()
        notice = isPremium ? L10n.restoreSuccess : L10n.restoreNothing
    }

    // MARK: - Transactions

    private func handle(_ verification: VerificationResult<Transaction>) async {
        // Une transaction dont la signature n'est pas valide est ignorée.
        guard case .verified(let transaction) = verification else { return }

        if transaction.productID == ProductID.premium {
            setPremium(transaction.revocationDate == nil)
        }
        await transaction.finish()
    }

    private func setPremium(_ unlocked: Bool) {
        let changed = unlocked != PremiumAccess.isUnlocked
        PremiumAccess.setUnlocked(unlocked)
        if isPremium != unlocked { isPremium = unlocked }
        if changed {
            ThemeStore.shared.refresh()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}

// MARK: - Thème

/// Rend le thème observable : un changement redessine l'interface.
@MainActor
final class ThemeStore: ObservableObject {

    static let shared = ThemeStore()

    @Published private(set) var theme: AppTheme = AppTheme.current
    @Published private(set) var widgetStyle: WidgetStyle = WidgetStyle.current

    private init() {}

    func select(_ theme: AppTheme) {
        AppTheme.save(theme)
        refresh()
    }

    func select(_ style: WidgetStyle) {
        WidgetStyle.save(style)
        refresh()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Relit les valeurs effectives (le premium a pu changer).
    func refresh() {
        if theme != AppTheme.current { theme = AppTheme.current }
        if widgetStyle != WidgetStyle.current { widgetStyle = WidgetStyle.current }
    }
}
