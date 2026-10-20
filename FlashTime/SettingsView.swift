//
//  SettingsView.swift
//  FlashTime
//

internal import Photos
internal import PhotosUI   // presentLimitedLibraryPicker(from:) est déclaré ici, pas dans Photos
import SwiftUI
import UIKit
import WidgetKit

struct SettingsView: View {

    @State var settings: MemorySettings
    /// Appelé à la fermeture, quelle qu'elle soit (bouton ou balayage) :
    /// les réglages ne sont jamais perdus.
    let onSave: (MemorySettings) -> Void
    let onReplayTutorial: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @ObservedObject private var languageStore = LanguageStore.shared

    @State private var hiddenCount = HiddenPhotos.identifiers.count
    @State private var showPrivacy = false
    @State private var showWidgetHelp = false

    private var accessState: PhotoAccessState { PhotoAccess.current }

    var body: some View {
        ZStack {
            FT.Palette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                FTTopBar(title: L10n.settings) {
                    FTBarButton(title: L10n.done, prominent: true) { dismiss() }
                }

                ScrollView {
                    VStack(spacing: 0) {
                        timeWindowSection
                        filtersSection
                        hiddenSection
                        limitedSection
                        languageSection
                        helpSection
                        aboutSection
                    }
                    .frame(maxWidth: 640)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)
            }
        }
        .preferredColorScheme(.dark)
        .onDisappear { onSave(settings) }
        .sheet(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
    }

    // MARK: - Sections

    private var timeWindowSection: some View {
        VStack(spacing: 0) {
            FTSectionBanner(title: L10n.timeWindow)

            stepperRow(
                label: L10n.from,
                value: L10n.years(settings.minYearsBack),
                canDecrease: settings.minYearsBack > 1,
                canIncrease: settings.minYearsBack < settings.maxYearsBack,
                onDecrease: { settings.minYearsBack -= 1 },
                onIncrease: { settings.minYearsBack += 1 }
            )

            divider

            stepperRow(
                label: L10n.upTo,
                value: L10n.years(settings.maxYearsBack),
                canDecrease: settings.maxYearsBack > settings.minYearsBack,
                canIncrease: settings.maxYearsBack < 50,
                onDecrease: { settings.maxYearsBack -= 1 },
                onIncrease: { settings.maxYearsBack += 1 }
            )

            footnote(L10n.windowFootnote(min: settings.minYearsBack, max: settings.maxYearsBack))
        }
    }

    private var filtersSection: some View {
        VStack(spacing: 0) {
            FTSectionBanner(title: L10n.filters)

            Toggle(isOn: $settings.excludeScreenshots) {
                Text(L10n.excludeScreenshots)
                    .font(FT.Typography.body(15))
                    .foregroundStyle(FT.Palette.textPrimary)
            }
            .tint(FT.Palette.accent)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .padding(.bottom, 12)
        }
    }

    @ViewBuilder
    private var hiddenSection: some View {
        if hiddenCount > 0 {
            FTSectionBanner(title: L10n.hiddenPhotos)

            footnote(L10n.hiddenFootnote(hiddenCount))

            Button(L10n.showAllAgain) {
                HiddenPhotos.clear()
                hiddenCount = 0
                WidgetCenter.shared.reloadAllTimelines()
            }
            .buttonStyle(.ftOutline)
            .padding(.bottom, 28)
        }
    }

    @ViewBuilder
    private var limitedSection: some View {
        if accessState == .limited {
            FTSectionBanner(title: L10n.selection)

            footnote(L10n.limitedFootnote)

            Button(L10n.chooseMorePhotos) {
                presentLimitedPicker()
            }
            .buttonStyle(.ftOutline)
            .padding(.bottom, 28)
        }
    }

    private var languageSection: some View {
        VStack(spacing: 0) {
            FTSectionBanner(title: L10n.language)

            ForEach(AppLanguage.allCases) { language in
                Button {
                    languageStore.select(language)
                } label: {
                    HStack {
                        Text(language.nativeName)
                            .font(FT.Typography.body(15))
                            .foregroundStyle(FT.Palette.textPrimary)
                        Spacer()
                        if language == languageStore.language {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13))
                                .foregroundStyle(FT.Palette.accent)
                        }
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 48)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(language == languageStore.language ? .isSelected : [])

                if language != AppLanguage.allCases.last {
                    divider
                }
            }

            Color.clear.frame(height: 20)
        }
    }

    private var helpSection: some View {
        VStack(spacing: 0) {
            FTSectionBanner(title: L10n.help)

            linkRow(L10n.replayTutorial, symbol: "play.circle") {
                onReplayTutorial()
            }

            divider

            linkRow(L10n.howToAddWidget,
                    symbol: showWidgetHelp ? "chevron.up" : "chevron.down") {
                withAnimation(.easeOut(duration: 0.2)) { showWidgetHelp.toggle() }
            }

            if showWidgetHelp {
                footnote(L10n.coachWidgetBody)
                    .transition(.opacity)
            } else {
                Color.clear.frame(height: 20)
            }
        }
    }

    private var aboutSection: some View {
        VStack(spacing: 0) {
            FTSectionBanner(title: L10n.about)

            linkRow(L10n.privacyPolicy, symbol: "lock.shield") {
                showPrivacy = true
            }

            divider

            linkRow(L10n.contactSupport, symbol: "envelope") {
                if let url = supportMailURL { openURL(url) }
            }

            divider

            linkRow(L10n.systemSettings, symbol: "gear") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }

            Text(L10n.version(AppInfo.version, AppInfo.build))
                .font(FT.Typography.body(11))
                .foregroundStyle(FT.Palette.textTertiary)
                .padding(.top, 26)
                .padding(.bottom, 40)
        }
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: if canIncrease { onIncrease() }
            case .decrement: if canDecrease { onDecrease() }
            @unknown default: break
            }
        }
    }

    private func stepperButton(symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(enabled ? FT.Palette.textPrimary : FT.Palette.textTertiary)
                .frame(width: 44, height: 34)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func linkRow(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(FT.Typography.body(15))
                    .foregroundStyle(FT.Palette.textPrimary)
                Spacer()
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(FT.Palette.textSecondary)
            }
            .padding(.horizontal, 20)
            .frame(height: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func footnote(_ text: String) -> some View {
        Text(text)
            .font(FT.Typography.body(12))
            .foregroundStyle(FT.Palette.textTertiary)
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)
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

    private var supportMailURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = AppInfo.supportEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: "FlashTime \(AppInfo.version) (\(AppInfo.build))")
        ]
        return components.url
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
    SettingsView(settings: .default, onSave: { _ in }, onReplayTutorial: {})
}
