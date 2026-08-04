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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
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
