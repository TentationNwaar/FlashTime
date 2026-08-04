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
                icon: "calendar",
                title: "Pas de souvenir",
                detail: "Aucune photo prise un tel jour les années passées."
            )
        case .noAccess:
            message(
                icon: "lock",
                title: "Accès requis",
                detail: "Ouvrez FlashTime pour autoriser l'accès à vos photos."
            )
        case .placeholder:
            message(
                icon: "photo.stack",
                title: "FlashTime",
                detail: "Vos souvenirs du jour."
            )
        }
    }

    private func memoryContent(_ memory: MemoryPhoto) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(memory.title)
                        .font(titleFont)
                        .fontWeight(.bold)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)

                    if family != .systemSmall {
                        Text(memory.subtitle)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                }

                if family != .systemSmall, entry.total > 1 {
                    Spacer(minLength: 8)
                    Text("\(entry.index)/\(entry.total)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.5), radius: 4, y: 1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, family == .systemSmall ? 12 : 16)
            .padding(.bottom, family == .systemSmall ? 12 : 16)
            .padding(.top, 40)
            .background(
                LinearGradient(
                    colors: [.black.opacity(0), .black.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private func message(icon: String, title: String, detail: String) -> some View {
        // Le fond est toujours sombre dans ces états : on force le blanc plutôt
        // que de dépendre du mode clair/sombre du système.
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white.opacity(0.7))
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            if family != .systemSmall {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Fond

    @ViewBuilder
    private var background: some View {
        if let data = entry.imageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            LinearGradient(
                colors: [Color(white: 0.16), Color(white: 0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var titleFont: Font {
        switch family {
        case .systemSmall: return .headline
        case .systemMedium: return .title3
        default: return .title2
        }
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
