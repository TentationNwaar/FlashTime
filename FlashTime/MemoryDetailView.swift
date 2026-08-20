//
//  MemoryDetailView.swift
//  FlashTime
//

import SwiftUI
import UIKit

/// Affichage plein écran d'un souvenir, avec le titre « Il y a X ans ».
struct MemoryDetailView: View {

    let memory: MemoryPhoto

    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?
    @State private var revealed = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
                    .opacity(revealed ? 1 : 0)
            }

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .light))
                            .foregroundStyle(FT.Palette.textPrimary)
                            .frame(width: 40, height: 40)
                            .background(.black.opacity(0.25))
                            .overlay {
                                Rectangle()
                                    .stroke(FT.Palette.textPrimary.opacity(0.35),
                                            lineWidth: FT.Metric.hairline)
                            }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer()

                caption
                    .padding(.bottom, 44)
            }
        }
        .task {
            // Taille généreuse : PhotoKit renvoie au plus la taille réelle de la
            // photo, donc on ne gaspille rien sur les images plus petites.
            let target = CGSize(width: 2400, height: 2400)
            let data = await MemoriesFetcher.imageData(
                for: memory.id,
                targetSize: target,
                cropping: .fit,
                compression: 0.9
            )
            if let data { image = UIImage(data: data) }
            withAnimation(.easeOut(duration: 0.35)) { revealed = true }
        }
    }

    private var caption: some View {
        VStack(spacing: 5) {
            Text(memory.title)
                .font(FT.Typography.screenTitle(16))
                .tracking(FT.Metric.titleTracking)
                .foregroundStyle(FT.Palette.textPrimary)

            Text(memory.subtitle)
                .font(FT.Typography.body(12))
                .foregroundStyle(FT.Palette.textPrimary.opacity(0.6))
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 34)
        .background(.black.opacity(0.35))
        .overlay {
            Rectangle()
                .stroke(FT.Palette.textPrimary.opacity(0.25), lineWidth: FT.Metric.hairline)
        }
    }
}
