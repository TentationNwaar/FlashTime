//
//  CoachMarks.swift
//  FlashTime
//
//  Bulles d'aide affichées pas à pas sur l'écran principal, après le tutoriel
//  d'accueil. Chaque bulle désigne un élément réel de l'interface : son cadre
//  est remonté par une préférence d'ancrage (`coachTarget`), puis l'overlay
//  assombrit l'écran en laissant cet élément visible.
//

import Combine
import SwiftUI

// MARK: - Étapes

/// Élément d'interface pouvant être désigné par une bulle.
nonisolated enum CoachTarget: Hashable, Sendable {
    case firstPhoto
    case dayNavigator
    case settingsButton
}

nonisolated enum CoachStep: String, CaseIterable, Identifiable, Sendable {
    case openPhoto
    case hidePhoto
    case browseDays
    case settings
    case widget

    var id: String { rawValue }

    /// `nil` : bulle centrée, sans élément désigné.
    var target: CoachTarget? {
        switch self {
        case .openPhoto, .hidePhoto: return .firstPhoto
        case .browseDays: return .dayNavigator
        case .settings: return .settingsButton
        case .widget: return nil
        }
    }

    var symbol: String {
        switch self {
        case .openPhoto: return "hand.tap"
        case .hidePhoto: return "eye.slash"
        case .browseDays: return "calendar"
        case .settings: return "slider.horizontal.3"
        case .widget: return "apps.iphone.badge.plus"
        }
    }

    var title: String {
        switch self {
        case .openPhoto: return L10n.coachOpenTitle
        case .hidePhoto: return L10n.coachHideTitle
        case .browseDays: return L10n.coachDayTitle
        case .settings: return L10n.coachSettingsTitle
        case .widget: return L10n.coachWidgetTitle
        }
    }

    var message: String {
        switch self {
        case .openPhoto: return L10n.coachOpenBody
        case .hidePhoto: return L10n.coachHideBody
        case .browseDays: return L10n.coachDayBody
        case .settings: return L10n.coachSettingsBody
        case .widget: return L10n.coachWidgetBody
        }
    }
}

// MARK: - Progression

/// Mémorise les bulles déjà vues. Une étape dont l'élément n'est pas affiché
/// (par exemple aucune photo ce jour-là) est simplement reportée : elle
/// apparaîtra le jour où l'élément existe.
@MainActor
final class CoachMarks: ObservableObject {

    @Published private(set) var seen: Set<String>

    private let key = "coach.seenSteps"

    init() {
        seen = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
    }

    /// Étapes non vues dont l'élément est actuellement affiché, dans l'ordre.
    func pending(available: Set<CoachTarget>) -> [CoachStep] {
        CoachStep.allCases.filter { step in
            guard !seen.contains(step.rawValue) else { return false }
            guard let target = step.target else { return true }
            return available.contains(target)
        }
    }

    func markSeen(_ step: CoachStep) {
        seen.insert(step.rawValue)
        save()
    }

    func skipAll() {
        seen = Set(CoachStep.allCases.map(\.rawValue))
        save()
    }

    func reset() {
        seen = []
        save()
    }

    private func save() {
        UserDefaults.standard.set(Array(seen), forKey: key)
    }
}

// MARK: - Ancrage

nonisolated struct CoachAnchorKey: PreferenceKey {
    static var defaultValue: [CoachTarget: Anchor<CGRect>] { [:] }

    static func reduce(
        value: inout [CoachTarget: Anchor<CGRect>],
        nextValue: () -> [CoachTarget: Anchor<CGRect>]
    ) {
        value.merge(nextValue()) { _, new in new }
    }
}

extension View {
    /// Déclare la vue comme cible possible d'une bulle d'aide.
    func coachTarget(_ target: CoachTarget, active: Bool = true) -> some View {
        anchorPreference(key: CoachAnchorKey.self, value: .bounds) { anchor in
            active ? [target: anchor] : [:]
        }
    }
}

// MARK: - Overlay

struct CoachMarkOverlay: View {

    let step: CoachStep
    let anchor: Anchor<CGRect>?
    let index: Int
    let total: Int
    let onNext: () -> Void
    let onSkip: () -> Void

    @State private var appeared = false

    private let margin: CGFloat = 16
    private let gap: CGFloat = 14

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let screen = CGRect(origin: .zero, size: size)
            // Cadre de l'élément désigné, ignoré s'il est hors de l'écran.
            let target: CGRect? = anchor
                .map { proxy[$0].insetBy(dx: -6, dy: -6) }
                .flatMap { $0.intersects(screen) ? $0.intersection(screen) : nil }

            ZStack(alignment: .topLeading) {
                dimming(size: size, hole: target)

                if let target {
                    Rectangle()
                        .stroke(FT.Palette.accent, lineWidth: 1.5)
                        .frame(width: target.width, height: target.height)
                        .offset(x: target.minX, y: target.minY)
                        .allowsHitTesting(false)
                }

                bubblePlacement(size: size, target: target)
            }
            .frame(width: size.width, height: size.height, alignment: .topLeading)
        }
        .ignoresSafeArea()
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) { appeared = true }
        }
        .accessibilityAddTraits(.isModal)
    }

    // MARK: Fond assombri

    private func dimming(size: CGSize, hole: CGRect?) -> some View {
        Path { path in
            path.addRect(CGRect(origin: .zero, size: size))
            if let hole { path.addRect(hole) }
        }
        .fill(Color.black.opacity(0.66), style: FillStyle(eoFill: true))
        // Le fond capte les touchers : l'utilisateur ne peut pas interagir
        // avec l'écran tant que la bulle est ouverte.
        .contentShape(Rectangle())
        .onTapGesture { }
    }

    // MARK: Position de la bulle

    @ViewBuilder
    private func bubblePlacement(size: CGSize, target: CGRect?) -> some View {
        let width = min(size.width - 2 * margin, 340)

        if let target {
            // Bulle sous l'élément s'il est dans la moitié haute, au-dessus sinon.
            let below = target.midY < size.height / 2
            let x = min(max(target.midX - width / 2, margin), size.width - width - margin)
            let arrowX = min(max(target.midX - x, 18), width - 18)

            VStack(alignment: .leading, spacing: 0) {
                if below {
                    Color.clear.frame(height: target.maxY + gap)
                    bubble(width: width, arrowX: arrowX, arrowOnTop: true)
                    Spacer(minLength: 0)
                } else {
                    Spacer(minLength: 0)
                    bubble(width: width, arrowX: arrowX, arrowOnTop: false)
                    Color.clear.frame(height: max(size.height - target.minY + gap, 0))
                }
            }
            .frame(width: width, height: size.height, alignment: .topLeading)
            .offset(x: x)
        } else {
            bubble(width: width, arrowX: nil, arrowOnTop: true)
                .frame(width: size.width, height: size.height)
        }
    }

    // MARK: Bulle

    private func bubble(width: CGFloat, arrowX: CGFloat?, arrowOnTop: Bool) -> some View {
        VStack(spacing: 0) {
            if arrowOnTop, let arrowX { arrow(pointingUp: true, x: arrowX) }

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: step.symbol)
                        .font(.system(size: 15, weight: .light))
                        .foregroundStyle(FT.Palette.accent)
                    Text(step.title)
                        .ftSectionLabel()
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(step.message)
                    .font(FT.Typography.body(14))
                    .foregroundStyle(FT.Palette.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Text("\(index)/\(total)")
                        .font(FT.Typography.body(11).monospacedDigit())
                        .foregroundStyle(FT.Palette.textTertiary)

                    Spacer()

                    if index < total {
                        FTBarButton(title: L10n.skip, action: onSkip)
                            .padding(.trailing, 18)
                    }
                    FTBarButton(title: index < total ? L10n.next : L10n.gotIt, prominent: true, action: onNext)
                }
                .padding(.top, 4)
            }
            .padding(16)
            .frame(width: width, alignment: .leading)
            .background(FT.Palette.surface)
            .overlay {
                Rectangle().stroke(FT.Palette.separator, lineWidth: FT.Metric.hairline)
            }

            if !arrowOnTop, let arrowX { arrow(pointingUp: false, x: arrowX) }
        }
        .frame(width: width)
        .shadow(color: .black.opacity(0.4), radius: 12, y: 4)
        .accessibilityElement(children: .contain)
    }

    private func arrow(pointingUp: Bool, x: CGFloat) -> some View {
        Triangle()
            .fill(FT.Palette.surface)
            .frame(width: 16, height: 8)
            .rotationEffect(pointingUp ? .zero : .degrees(180))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, x - 8)
            .offset(y: pointingUp ? 1 : -1)
    }
}

/// Pointe de la bulle, orientée vers le haut par défaut.
nonisolated private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}
