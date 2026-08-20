//
//  LaunchOverlayView.swift
//  FlashTime
//
//  Écran de démarrage animé. Il recouvre l'interface pendant la première
//  recherche des souvenirs, ce qui remplace l'indicateur de chargement.
//

import SwiftUI

struct LaunchOverlayView: View {

    /// Pilote l'apparition du logo, déclenchée à l'affichage de la vue.
    @State private var appeared = false

    var body: some View {
        ZStack {
            // Même couleur que l'écran de lancement système : la transition
            // entre les deux est invisible.
            Color("LaunchBackground")
                .ignoresSafeArea()

            Image("LaunchLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 190, height: 190)
                .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.88)
                .blur(radius: appeared ? 0 : 6)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.55)) {
                appeared = true
            }
        }
    }
}

#Preview {
    LaunchOverlayView()
}
