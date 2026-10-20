//
//  LanguageStore.swift
//  FlashTime
//
//  Rend la langue observable par SwiftUI : un changement redessine
//  l'interface immédiatement, sans relancer l'app.
//

import Combine
import Foundation
import WidgetKit

@MainActor
final class LanguageStore: ObservableObject {

    static let shared = LanguageStore()

    @Published private(set) var language: AppLanguage = AppLanguage.current

    private init() {}

    func select(_ language: AppLanguage) {
        AppLanguage.save(language)
        if language != self.language {
            self.language = language
        }
        // Le widget lit la langue dans l'App Group : on le reconstruit.
        WidgetCenter.shared.reloadAllTimelines()
    }
}
