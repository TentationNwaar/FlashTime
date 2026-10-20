//
//  OnboardingView.swift
//  FlashTime
//
//  Tutoriel d'accueil : choix de la langue, puis quatre pages qui présentent
//  le principe de l'app. Rejouable depuis les réglages (sans la page langue).
//

import SwiftUI

struct OnboardingView: View {

    /// Vrai au premier lancement : la première page propose la langue.
    let includesLanguage: Bool
    let onFinish: () -> Void

    @ObservedObject private var languageStore = LanguageStore.shared
    @State private var page = 0
    @State private var showPrivacy = false

    private enum Page: Hashable {
        case language, memories, widget, curate, privacy
    }

    private var pages: [Page] {
        (includesLanguage ? [.language] : []) + [.memories, .widget, .curate, .privacy]
    }

    private var isLast: Bool { page == pages.count - 1 }

    var body: some View {
        ZStack {
            FT.Palette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        content(for: item)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.25), value: page)

                footer
            }
        }
        .sheet(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
    }

    // MARK: - En-tête et pied

    private var header: some View {
        HStack {
            Spacer()
            if !isLast {
                FTBarButton(title: L10n.skip) { finish() }
            }
        }
        .frame(height: 30)
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var footer: some View {
        VStack(spacing: 22) {
            indicator

            HStack(spacing: 12) {
                if page > 0 {
                    Button(L10n.back) {
                        withAnimation { page -= 1 }
                    }
                    .buttonStyle(.ftOutline)
                }

                Button(isLast ? L10n.getStarted : L10n.next) {
                    if isLast {
                        finish()
                    } else {
                        withAnimation { page += 1 }
                    }
                }
                .buttonStyle(.ftOutlineProminent)
            }
        }
        .padding(.bottom, 36)
    }

    /// Indicateur de page : petits carrés, fidèles à la DA anguleuse.
    private var indicator: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { index in
                Rectangle()
                    .fill(index == page ? FT.Palette.textPrimary : FT.Palette.separator)
                    .frame(width: index == page ? 18 : 6, height: 6)
            }
        }
        .animation(.easeOut(duration: 0.2), value: page)
        .accessibilityElement()
        .accessibilityLabel("\(page + 1)/\(pages.count)")
    }

    // MARK: - Pages

    @ViewBuilder
    private func content(for item: Page) -> some View {
        switch item {
        case .language:
            languagePage
        case .memories:
            infoPage(
                illustration: symbol("photo.on.rectangle.angled"),
                title: L10n.introMemoriesTitle,
                message: L10n.introMemoriesBody
            )
        case .widget:
            infoPage(
                illustration: AnyView(widgetMock),
                title: L10n.introWidgetTitle,
                message: L10n.introWidgetBody
            )
        case .curate:
            infoPage(
                illustration: symbol("hand.tap"),
                title: L10n.introCurateTitle,
                message: L10n.introCurateBody
            )
        case .privacy:
            infoPage(
                illustration: symbol("lock.shield"),
                title: L10n.introPrivacyTitle,
                message: L10n.introPrivacyBody,
                extra: AnyView(
                    Button(L10n.privacyPolicy) { showPrivacy = true }
                        .font(FT.Typography.body(13))
                        .foregroundStyle(FT.Palette.accent)
                        .padding(.top, 18)
                )
            )
        }
    }

    private var languagePage: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "globe")
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundStyle(FT.Palette.textTertiary)
                .padding(.bottom, 28)

            Text(L10n.chooseLanguageTitle)
                .font(FT.Typography.display(25))
                .foregroundStyle(FT.Palette.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 28)

            VStack(spacing: 0) {
                ForEach(AppLanguage.allCases) { language in
                    Button {
                        languageStore.select(language)
                    } label: {
                        HStack {
                            Text(language.nativeName)
                                .font(FT.Typography.body(16))
                                .foregroundStyle(FT.Palette.textPrimary)
                            Spacer()
                            if language == languageStore.language {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundStyle(FT.Palette.accent)
                            }
                        }
                        .padding(.horizontal, 18)
                        .frame(height: 50)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(language == languageStore.language ? .isSelected : [])

                    if language != AppLanguage.allCases.last {
                        Rectangle()
                            .fill(FT.Palette.separator)
                            .frame(height: FT.Metric.hairline)
                    }
                }
            }
            .overlay {
                Rectangle().stroke(FT.Palette.separator, lineWidth: FT.Metric.hairline)
            }
            .frame(maxWidth: 360)
            .padding(.horizontal, 32)

            Text(L10n.chooseLanguageFootnote)
                .font(FT.Typography.body(12))
                .foregroundStyle(FT.Palette.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.top, 16)
                .padding(.horizontal, 40)

            Spacer()
        }
    }

    private func infoPage(
        illustration: AnyView,
        title: String,
        message: String,
        extra: AnyView? = nil
    ) -> some View {
        VStack(spacing: 0) {
            Spacer()

            illustration
                .padding(.bottom, 34)

            Text(title)
                .font(FT.Typography.display(26))
                .foregroundStyle(FT.Palette.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 14)

            Text(message)
                .font(FT.Typography.body(15))
                .foregroundStyle(FT.Palette.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 420)
                .padding(.horizontal, 40)

            if let extra { extra }

            Spacer()
        }
    }

    private func symbol(_ name: String) -> AnyView {
        AnyView(
            Image(systemName: name)
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(FT.Palette.textTertiary)
                .frame(height: 150)
        )
    }

    /// Représentation simplifiée du widget, pour la page qui le présente.
    private var widgetMock: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [FT.Palette.surface, FT.Palette.elevated],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )

            Image(systemName: "photo")
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundStyle(FT.Palette.textTertiary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Text(L10n.yearsAgo(10))
                .font(FT.Typography.screenTitle(13))
                .tracking(2.4)
                .foregroundStyle(FT.Palette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(13)
        }
        .frame(width: 150, height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(FT.Palette.separator, lineWidth: FT.Metric.hairline)
        }
        .accessibilityHidden(true)
    }

    // MARK: - Fin

    private func finish() {
        // Enregistre explicitement la langue, même si l'utilisateur a gardé
        // celle proposée par défaut : la page ne sera plus montrée.
        languageStore.select(languageStore.language)
        onFinish()
    }
}

#Preview {
    OnboardingView(includesLanguage: true) {}
        .preferredColorScheme(.dark)
}
