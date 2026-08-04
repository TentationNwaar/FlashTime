//
//  MemoryDetailView.swift
//  FlashTime
//

import SwiftUI
import UIKit
import Photos

/// Affichage plein écran d'un souvenir, avec le titre « Il y a X ans ».
struct MemoryDetailView: View {

    let memory: MemoryPhoto

    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
            } else {
                ProgressView()
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .tint(.white)
                }
                .padding()

                Spacer()

                VStack(spacing: 4) {
                    Text(memory.title)
                        .font(.title2.weight(.bold))
                    Text(memory.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                }
                .foregroundStyle(.white)
                .padding(.vertical, 14)
                .padding(.horizontal, 24)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.bottom, 40)
            }
        }
        .task {
            // Taille généreuse : PhotoKit renvoie au plus la taille réelle de la
            // photo, donc on ne gaspille rien sur les images plus petites.
            let target = CGSize(width: 2400, height: 2400)
            let data = await MemoriesFetcher.imageData(
                for: memory.id,
                targetSize: target,
                contentMode: .aspectFit,
                compression: 0.9
            )
            if let data { image = UIImage(data: data) }
        }
    }
}
