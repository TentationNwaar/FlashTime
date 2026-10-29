//
//  FlashTimeApp.swift
//  FlashTime
//
//  Created by Maxence Weyermann on 04.08.2026.
//

import SwiftUI
import WidgetKit

@main
struct FlashTimeApp: App {

    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Démarre l'écoute des transactions StoreKit dès le lancement, comme
        // le recommande Apple (achats approuvés plus tard, remboursements).
        _ = PremiumStore.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { _, phase in
            // Quand l'app passe en arrière-plan, on demande au widget de se
            // reconstruire : l'autorisation ou les réglages ont pu changer.
            if phase == .background {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}
