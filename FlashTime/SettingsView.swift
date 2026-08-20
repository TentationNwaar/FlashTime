//
//  SettingsView.swift
//  FlashTime
//

internal import Photos
internal import PhotosUI   // presentLimitedLibraryPicker(from:) est déclaré ici, pas dans Photos
import SwiftUI
import UIKit

struct SettingsView: View {

    @State var settings: MemorySettings
    let onSave: (MemorySettings) -> Void

    @Environment(\.dismiss) private var dismiss

    private var accessState: PhotoAccessState { PhotoAccess.current }

    var body: some View {
        ZStack {
            FT.Palette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                FTTopBar(title: "Réglages") {
                    FTBarButton(title: "Annuler") { dismiss() }
                } trailing: {
                    FTBarButton(title: "Enregistrer", prominent: true) {
                        onSave(settings)
                        dismiss()
                    }
                }

                ScrollView {
                    VStack(spacing: 0) {
                        FTSectionBanner(title: "Fenêtre de temps")

                        stepperRow(
                            label: "À partir de",
                            value: yearsText(settings.minYearsBack),
                            canDecrease: settings.minYearsBack > 1,
                            canIncrease: settings.minYearsBack < settings.maxYearsBack,
                            onDecrease: { settings.minYearsBack -= 1 },
                            onIncrease: { settings.minYearsBack += 1 }
                        )

                        divider

                        stepperRow(
                            label: "Jusqu'à",
                            value: yearsText(settings.maxYearsBack),
                            canDecrease: settings.maxYearsBack > settings.minYearsBack,
                            canIncrease: settings.maxYearsBack < 50,
                            onDecrease: { settings.maxYearsBack -= 1 },
                            onIncrease: { settings.maxYearsBack += 1 }
                        )

                        footnote("FlashTime cherche les photos prises le même jour, entre \(yearsText(settings.minYearsBack)) et \(yearsText(settings.maxYearsBack)) en arrière.")

                        FTSectionBanner(title: "Filtres")

                        toggleRow(
                            label: "Exclure les captures d'écran",
                            isOn: $settings.excludeScreenshots
                        )

                        if accessState == .limited {
                            FTSectionBanner(title: "Sélection")

                            footnote("FlashTime n'a accès qu'à une sélection de photos. Élargissez-la pour retrouver davantage de souvenirs.")

                            Button("Choisir davantage de photos") {
                                presentLimitedPicker()
                            }
                            .buttonStyle(.ftOutline)
                            .padding(.bottom, 28)
                        }

                        Button("Réglages système de l'app") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .buttonStyle(.ftOutline)
                        .padding(.top, 12)
                        .padding(.bottom, 40)
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Lignes

    private func stepperRow(
        label: String,
        value: String,
        canDecrease: Bool,
        canIncrease: Bool,
        onDecrease: @escaping () -> Void,
        onIncrease: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 16) {
            Text(label)
                .font(FT.Typography.body(15))
                .foregroundStyle(FT.Palette.textPrimary)

            Spacer(minLength: 8)

            Text(value)
                .font(FT.Typography.sectionLabel(14))
                .tracking(FT.Metric.labelTracking)
                .foregroundStyle(FT.Palette.textSecondary)
                .monospacedDigit()

            HStack(spacing: 0) {
                stepperButton(symbol: "minus", enabled: canDecrease, action: onDecrease)
                Rectangle()
                    .fill(FT.Palette.separator)
                    .frame(width: FT.Metric.hairline, height: 30)
                stepperButton(symbol: "plus", enabled: canIncrease, action: onIncrease)
            }
            .overlay {
                Rectangle().stroke(FT.Palette.separator, lineWidth: FT.Metric.hairline)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private func stepperButton(symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(enabled ? FT.Palette.textPrimary : FT.Palette.textTertiary)
                .frame(width: 38, height: 30)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func toggleRow(label: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(label)
                .font(FT.Typography.body(15))
                .foregroundStyle(FT.Palette.textPrimary)
        }
        .tint(FT.Palette.accent)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private func footnote(_ text: String) -> some View {
        Text(text)
            .font(FT.Typography.body(12))
            .foregroundStyle(FT.Palette.textTertiary)
            .lineSpacing(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 26)
    }

    private var divider: some View {
        Rectangle()
            .fill(FT.Palette.separator)
            .frame(height: FT.Metric.hairline)
            .padding(.leading, 20)
    }

    private func yearsText(_ value: Int) -> String {
        value == 1 ? "1 an" : "\(value) ans"
    }

    // MARK: - Accès limité

    private func presentLimitedPicker() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let root = scene.keyWindow?.rootViewController else { return }
        // Le contrôleur présenté (cette feuille) est celui depuis lequel présenter.
        let presenter = root.presentedViewController ?? root
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: presenter)
    }
}

#Preview {
    SettingsView(settings: .default) { _ in }
}
