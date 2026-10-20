//
//  MemoryWidgetView.swift
//  FlashTimeWidget
//

import AppIntents   // Button(intent:) vient de la surcouche AppIntents + SwiftUI
import SwiftUI
import UIKit
import WidgetKit

struct MemoryWidgetView: View {

    let entry: MemoryEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        content
            .containerBackground(for: .widget) {
                background
            }
            .widgetURL(link)
    }

    /// Toucher le widget ouvre l'app directement sur la photo affichée.
    private var link: URL? {
        guard case .memory(let memory) = entry.state else { return nil }
        var components = URLComponents()
        components.scheme = "flashtime"
        components.host = "memory"
        components.queryItems = [URLQueryItem(name: "id", value: memory.id)]
        return components.url
    }

    // MARK: - Contenu

    @ViewBuilder
    private var content: some View {
        switch entry.state {
        case .memory(let memory):
            memoryContent(memory)
        case .empty:
            message(
                title: L10n.widgetEmptyTitle,
                detail: L10n.widgetEmptyDetail
            )
        case .noAccess:
            message(
                title: L10n.widgetAccessTitle,
                detail: L10n.widgetAccessDetail
            )
        case .placeholder:
            message(
                title: L10n.appName,
                detail: L10n.widgetPlaceholderDetail
            )
        }
    }

    private func memoryContent(_ memory: MemoryPhoto) -> some View {
        captionLayer(memory)
            .overlay {
                if entry.total > 1 {
                    navigationArrows
                }
            }
    }

    /// Flèches latérales : souvenir précédent / suivant de la journée.
    private var navigationArrows: some View {
        HStack {
            arrowButton("chevron.left", step: -1)
            Spacer(minLength: 0)
            arrowButton("chevron.right", step: 1)
        }
        .padding(.horizontal, family == .systemSmall ? 4 : 8)
        // Les flèches restent au-dessus de la légende, centrées sur la photo.
        .padding(.bottom, family == .systemSmall ? 22 : 30)
    }

    private func arrowButton(_ symbol: String, step: Int) -> some View {
        let side: CGFloat = family == .systemSmall ? 26 : 32
        return Button(intent: ShowAdjacentMemoryIntent(step: step)) {
            Image(systemName: symbol)
                .font(.system(size: family == .systemSmall ? 11 : 13, weight: .regular))
                .foregroundStyle(.white)
                .frame(width: side, height: side)
                .background(.black.opacity(0.28))
                .overlay {
                    Rectangle()
                        .stroke(.white.opacity(0.35), lineWidth: FT.Metric.hairline)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(step < 0 ? L10n.previousMemory : L10n.nextMemory)
    }

    private func captionLayer(_ memory: MemoryPhoto) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(memory.title)
                        .font(titleFont)
                        .tracking(titleTracking)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)

                    if family != .systemSmall {
                        Text(memory.subtitle)
                            .font(.system(size: 11))
                            .tracking(0.4)
                            .foregroundStyle(.white.opacity(0.72))
                            .lineLimit(1)
                    }
                }

                if family != .systemSmall, entry.total > 1 {
                    Spacer(minLength: 8)
                    Text("\(entry.index)/\(entry.total)")
                        .font(.system(size: 10).monospacedDigit())
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.55), radius: 5, y: 1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, family == .systemSmall ? 13 : 17)
            .padding(.bottom, family == .systemSmall ? 13 : 16)
            .padding(.top, 48)
            .background(
                // Dégradé long et discret : la photo prime, le texte reste
                // lisible sans assombrir la moitié du widget.
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0), location: 0),
                        .init(color: .black.opacity(0.18), location: 0.45),
                        .init(color: .black.opacity(0.62), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private func message(title: String, detail: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(FT.Typography.sectionLabel(family == .systemSmall ? 12 : 13))
                .tracking(FT.Metric.labelTracking)
                .foregroundStyle(FT.Palette.textPrimary)
                .multilineTextAlignment(.center)

            if family != .systemSmall {
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(FT.Palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .center) {
            // Filet fin autour du message, écho des encadrés de l'app.
            Rectangle()
                .stroke(FT.Palette.separator, lineWidth: FT.Metric.hairline)
                .padding(family == .systemSmall ? 12 : 16)
        }
    }

    // MARK: - Fond

    @ViewBuilder
    private var background: some View {
        if let data = entry.imageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            FT.Palette.background
        }
    }

    // MARK: - Typographie

    /// Serif en petites capitales : « IL Y A 10 ANS ».
    private var titleFont: Font {
        switch family {
        case .systemSmall: return FT.Typography.screenTitle(13)
        case .systemMedium: return FT.Typography.screenTitle(16)
        default: return FT.Typography.screenTitle(19)
        }
    }

    private var titleTracking: CGFloat {
        family == .systemSmall ? 2.4 : FT.Metric.titleTracking
    }
}

// MARK: - Aperçus

#Preview(as: .systemSmall) {
    FlashTimeWidget()
} timeline: {
    MemoryEntry(
        date: .now,
        state: .memory(MemoryPhoto(id: "preview", creationDate: .now.addingTimeInterval(-10 * 365 * 86_400), yearsAgo: 10)),
        imageData: nil,
        index: 1,
        total: 4
    )
    MemoryEntry(date: .now, state: .empty, imageData: nil, index: 0, total: 0)
    MemoryEntry(date: .now, state: .noAccess, imageData: nil, index: 0, total: 0)
}

#Preview(as: .systemMedium) {
    FlashTimeWidget()
} timeline: {
    MemoryEntry(
        date: .now,
        state: .memory(MemoryPhoto(id: "preview", creationDate: .now.addingTimeInterval(-3 * 365 * 86_400), yearsAgo: 3)),
        imageData: nil,
        index: 2,
        total: 7
    )
}
