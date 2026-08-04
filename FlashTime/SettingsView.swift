//
//  SettingsView.swift
//  FlashTime
//

import Photos
import PhotosUI   // presentLimitedLibraryPicker(from:) est déclaré ici, pas dans Photos
import SwiftUI
import UIKit

struct SettingsView: View {

    @State var settings: MemorySettings
    let onSave: (MemorySettings) -> Void

    @Environment(\.dismiss) private var dismiss

    private var accessState: PhotoAccessState { PhotoAccess.current }

    var body: some View {
        NavigationStack {
            Form {
                // Section(_:content:) n'accepte pas de `footer:` : il faut la
                // forme complète header:/footer:.
                Section {
                    Stepper(
                        "À partir de \(settings.minYearsBack) an\(settings.minYearsBack > 1 ? "s" : "")",
                        value: $settings.minYearsBack,
                        in: 1...settings.maxYearsBack
                    )
                    Stepper(
                        "Jusqu'à \(settings.maxYearsBack) ans",
                        value: $settings.maxYearsBack,
                        in: settings.minYearsBack...50
                    )
                } header: {
                    Text("Fenêtre de temps")
                } footer: {
                    Text("FlashTime cherche les photos prises le même jour, entre \(settings.minYearsBack) et \(settings.maxYearsBack) ans en arrière.")
                }

                Section("Filtres") {
                    Toggle("Exclure les captures d'écran", isOn: $settings.excludeScreenshots)
                }

                if accessState == .limited {
                    Section {
                        Button("Choisir davantage de photos") {
                            presentLimitedPicker()
                        }
                    } footer: {
                        Text("FlashTime n'a accès qu'à une sélection de photos. Élargissez la sélection pour retrouver plus de souvenirs.")
                    }
                }

                Section {
                    Link("Réglages système de l'app",
                         destination: URL(string: UIApplication.openSettingsURLString)!)
                }
            }
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        onSave(settings)
                        dismiss()
                    }
                }
            }
        }
    }

    private func presentLimitedPicker() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let root = scene.keyWindow?.rootViewController else { return }
        // Le contrôleur présenté (cette feuille) est celui depuis lequel présenter.
        let presenter = root.presentedViewController ?? root
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: presenter)
    }
}
