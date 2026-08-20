//
//  MemoryWidgetView.swift
//  FlashTimeWidget
//

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
    }

    // MARK: - Contenu

    @ViewBuilder
    private var content: some View {
        switch entry.state {
        case .memory(let memory):
            memoryContent(memory)
        case .empty:
            message(
                title: "Pas de souvenir",
                detail: "Aucune photo prise un tel jour les années passées."
            )
        case .noAccess:
            message(
                title: "Accès requis",
                detail: "Ouvrez FlashTime pour autoriser l'accès à vos photos."
            )
        case .placeholder:
            message(
                title: "FlashTime",
                detail: "Vos souvenirs du jour."
            )
        }
    }

    private func memoryContent(_ memory: MemoryPhoto) -> some View {
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
