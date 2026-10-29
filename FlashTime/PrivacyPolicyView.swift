//
//  PrivacyPolicyView.swift
//  FlashTime
//
//  Politique de confidentialité consultable dans l'app, hors connexion.
//  Le texte est généré depuis la même source que la page web publiée
//  (docs/privacy.html) : les deux versions restent identiques.
//

import SwiftUI

nonisolated struct PrivacyPolicyContent: Sendable {
    let title: String
    let updated: String
    let sections: [(title: String, body: String)]

    static func content(for language: AppLanguage) -> PrivacyPolicyContent {
        switch language {
        case .english:
            return PrivacyPolicyContent(
                title: "Privacy policy",
                updated: "Effective date: 29 October 2026",
                sections: [
                    ("In short",
                     "FlashTime does not collect, transmit, share or sell any personal data. The app works entirely on your device: no account, no server, no tracking."),
                    ("Access to your photos",
                     "With your permission, FlashTime reads your photo library through Apple's Photos framework in order to find the photos taken on the same day in previous years. Photos and their dates are processed only on your device, to be displayed in the app and in the widget. They are never copied to a server. You can change or revoke this access at any time in Settings › Privacy & Security › Photos."),
                    ("Data stored on your device",
                     "Your settings (time window, screenshot filter, language), the list of photos you hide from the widget or mark as favourites (technical identifiers, not the images themselves), your theme and widget style, and the progress of the tutorial are stored locally, in a space shared only between the app and its widget. This data never leaves your device and is deleted when you uninstall the app."),
                    ("iCloud Photos",
                     "If your library uses iCloud Photos, iOS may download a photo from iCloud in order to display it. This transfer is handled by Apple under its own privacy policy; the developer receives no data from it."),
                    ("In-app purchases",
                     "FlashTime Premium and tips are sold through the App Store. Payment is processed entirely by Apple: the developer never receives your name, email address or payment details. The app only checks, on your device, the signed proof of purchase provided by Apple in order to unlock the premium features."),
                    ("No tracking, analytics or advertising",
                     "FlashTime contains no advertising, no analytics tool, no third-party SDK and does not track you across other apps or websites."),
                    ("Children",
                     "Because the app collects no data, it collects none from children either."),
                    ("Your rights",
                     "As the developer collects no personal data, there is no data to access, correct or delete on our side. Data stored on your device can be erased at any time by deleting the app. This policy is written in accordance with the Swiss Federal Act on Data Protection (FADP) and the EU General Data Protection Regulation (GDPR)."),
                    ("Changes",
                     "Any change to this policy will be published on this page, with an updated effective date."),
                    ("Contact",
                     "BubbleBlack, publisher of FlashTime. For any question: bubbleblack_@hotmail.com"),
                ]
            )
        case .french:
            return PrivacyPolicyContent(
                title: "Politique de confidentialité",
                updated: "Date d'entrée en vigueur : 29 octobre 2026",
                sections: [
                    ("En bref",
                     "FlashTime ne collecte, ne transmet, ne partage et ne vend aucune donnée personnelle. L'app fonctionne entièrement sur votre appareil : ni compte, ni serveur, ni pistage."),
                    ("Accès à vos photos",
                     "Avec votre autorisation, FlashTime lit votre photothèque au moyen du framework Photos d'Apple afin de retrouver les photos prises le même jour les années précédentes. Les photos et leurs dates sont traitées uniquement sur votre appareil, pour être affichées dans l'app et dans le widget. Elles ne sont jamais copiées vers un serveur. Vous pouvez modifier ou retirer cet accès à tout moment dans Réglages › Confidentialité et sécurité › Photos."),
                    ("Données conservées sur votre appareil",
                     "Vos réglages (fenêtre de temps, filtre des captures d'écran, langue), la liste des photos que vous écartez du widget ou marquez comme favorites (des identifiants techniques, pas les images elles-mêmes), votre thème et votre style de widget, et l'avancement du tutoriel sont enregistrés localement, dans un espace partagé uniquement entre l'app et son widget. Ces données ne quittent jamais votre appareil et sont supprimées lors de la désinstallation de l'app."),
                    ("Photos iCloud",
                     "Si votre photothèque utilise Photos iCloud, iOS peut télécharger une photo depuis iCloud pour l'afficher. Ce transfert est assuré par Apple, selon sa propre politique de confidentialité ; le développeur n'en reçoit aucune donnée."),
                    ("Achats intégrés",
                     "FlashTime Premium et les pourboires sont vendus via l'App Store. Le paiement est entièrement traité par Apple : le développeur ne reçoit jamais votre nom, votre adresse e-mail ni vos données de paiement. L'app vérifie seulement, sur votre appareil, la preuve d'achat signée fournie par Apple, afin de débloquer les fonctions premium."),
                    ("Ni pistage, ni statistiques, ni publicité",
                     "FlashTime ne contient aucune publicité, aucun outil de mesure d'audience, aucun SDK tiers, et ne vous suit pas à travers d'autres apps ou sites web."),
                    ("Enfants",
                     "L'app ne collectant aucune donnée, elle n'en collecte pas non plus auprès des enfants."),
                    ("Vos droits",
                     "Le développeur ne collectant aucune donnée personnelle, aucune donnée n'est à consulter, rectifier ou supprimer de son côté. Les données enregistrées sur votre appareil peuvent être effacées à tout moment en supprimant l'app. Cette politique est rédigée conformément à la loi fédérale suisse sur la protection des données (LPD) et au règlement général européen sur la protection des données (RGPD)."),
                    ("Modifications",
                     "Toute modification de cette politique sera publiée sur cette page, avec une date d'entrée en vigueur mise à jour."),
                    ("Contact",
                     "BubbleBlack, éditeur de FlashTime. Pour toute question : bubbleblack_@hotmail.com"),
                ]
            )
        case .italian:
            return PrivacyPolicyContent(
                title: "Informativa sulla privacy",
                updated: "Data di entrata in vigore: 29 ottobre 2026",
                sections: [
                    ("In breve",
                     "FlashTime non raccoglie, trasmette, condivide né vende alcun dato personale. L'app funziona interamente sul tuo dispositivo: nessun account, nessun server, nessun tracciamento."),
                    ("Accesso alle tue foto",
                     "Con la tua autorizzazione, FlashTime legge la tua libreria fotografica tramite il framework Foto di Apple per trovare le foto scattate nello stesso giorno negli anni precedenti. Le foto e le loro date vengono elaborate esclusivamente sul tuo dispositivo, per essere mostrate nell'app e nel widget. Non vengono mai copiate su un server. Puoi modificare o revocare questo accesso in qualsiasi momento in Impostazioni › Privacy e sicurezza › Foto."),
                    ("Dati conservati sul dispositivo",
                     "Le tue impostazioni (intervallo di tempo, filtro degli screenshot, lingua), l'elenco delle foto che nascondi dal widget o segni come preferite (identificativi tecnici, non le immagini), il tema e lo stile del widget e l'avanzamento del tutorial sono salvati localmente, in uno spazio condiviso solo tra l'app e il suo widget. Questi dati non lasciano mai il dispositivo e vengono eliminati quando disinstalli l'app."),
                    ("Foto di iCloud",
                     "Se la tua libreria usa Foto di iCloud, iOS può scaricare una foto da iCloud per mostrarla. Questo trasferimento è gestito da Apple secondo la propria informativa sulla privacy; lo sviluppatore non riceve alcun dato."),
                    ("Acquisti in-app",
                     "FlashTime Premium e le mance sono venduti tramite l'App Store. Il pagamento è gestito interamente da Apple: lo sviluppatore non riceve mai il tuo nome, il tuo indirizzo e-mail né i tuoi dati di pagamento. L'app verifica soltanto, sul dispositivo, la prova d'acquisto firmata fornita da Apple per sbloccare le funzioni premium."),
                    ("Nessun tracciamento, statistica o pubblicità",
                     "FlashTime non contiene pubblicità, strumenti di analisi né SDK di terze parti, e non ti traccia attraverso altre app o siti web."),
                    ("Minori",
                     "Poiché l'app non raccoglie alcun dato, non ne raccoglie nemmeno dai minori."),
                    ("I tuoi diritti",
                     "Poiché lo sviluppatore non raccoglie dati personali, non vi sono dati da consultare, correggere o cancellare da parte sua. I dati salvati sul dispositivo possono essere eliminati in qualsiasi momento cancellando l'app. La presente informativa è redatta in conformità alla legge federale svizzera sulla protezione dei dati (LPD) e al regolamento generale europeo sulla protezione dei dati (GDPR)."),
                    ("Modifiche",
                     "Qualsiasi modifica alla presente informativa sarà pubblicata su questa pagina, con una data di entrata in vigore aggiornata."),
                    ("Contatto",
                     "BubbleBlack, editore di FlashTime. Per qualsiasi domanda: bubbleblack_@hotmail.com"),
                ]
            )
        case .german:
            return PrivacyPolicyContent(
                title: "Datenschutzerklärung",
                updated: "Gültig ab: 29. Oktober 2026",
                sections: [
                    ("Kurz gesagt",
                     "FlashTime erhebt, übermittelt, teilt oder verkauft keine personenbezogenen Daten. Die App arbeitet vollständig auf Ihrem Gerät: kein Konto, kein Server, kein Tracking."),
                    ("Zugriff auf Ihre Fotos",
                     "Mit Ihrer Erlaubnis liest FlashTime Ihre Fotomediathek über das Fotos-Framework von Apple, um Fotos zu finden, die in früheren Jahren am selben Tag aufgenommen wurden. Die Fotos und ihre Aufnahmedaten werden ausschließlich auf Ihrem Gerät verarbeitet, um sie in der App und im Widget anzuzeigen. Sie werden niemals auf einen Server kopiert. Sie können diesen Zugriff jederzeit unter Einstellungen › Datenschutz & Sicherheit › Fotos ändern oder widerrufen."),
                    ("Auf Ihrem Gerät gespeicherte Daten",
                     "Ihre Einstellungen (Zeitraum, Filter für Bildschirmfotos, Sprache), die Liste der Fotos, die Sie im Widget ausblenden oder als Favoriten markieren (technische Kennungen, nicht die Bilder selbst), Ihr Thema und Widget-Stil sowie der Fortschritt des Tutorials werden lokal gespeichert, in einem Bereich, den nur die App und ihr Widget gemeinsam nutzen. Diese Daten verlassen Ihr Gerät nie und werden beim Löschen der App entfernt."),
                    ("iCloud-Fotos",
                     "Wenn Ihre Mediathek iCloud-Fotos verwendet, kann iOS ein Foto aus iCloud laden, um es anzuzeigen. Diese Übertragung erfolgt durch Apple gemäß dessen eigener Datenschutzerklärung; der Entwickler erhält dabei keine Daten."),
                    ("In-App-Käufe",
                     "FlashTime Premium und Trinkgelder werden über den App Store verkauft. Die Zahlung wird vollständig von Apple abgewickelt: Der Entwickler erhält weder Ihren Namen noch Ihre E-Mail-Adresse oder Zahlungsdaten. Die App prüft lediglich auf Ihrem Gerät den von Apple signierten Kaufnachweis, um die Premium-Funktionen freizuschalten."),
                    ("Kein Tracking, keine Statistiken, keine Werbung",
                     "FlashTime enthält keine Werbung, keine Analysewerkzeuge und keine SDKs von Drittanbietern und verfolgt Sie nicht über andere Apps oder Websites hinweg."),
                    ("Kinder",
                     "Da die App keine Daten erhebt, erhebt sie auch keine Daten von Kindern."),
                    ("Ihre Rechte",
                     "Da der Entwickler keine personenbezogenen Daten erhebt, gibt es bei ihm keine Daten, die eingesehen, berichtigt oder gelöscht werden könnten. Die auf Ihrem Gerät gespeicherten Daten lassen sich jederzeit durch Löschen der App entfernen. Diese Erklärung wurde gemäß dem Schweizer Bundesgesetz über den Datenschutz (DSG) und der EU-Datenschutz-Grundverordnung (DSGVO) verfasst."),
                    ("Änderungen",
                     "Jede Änderung dieser Erklärung wird auf dieser Seite mit aktualisiertem Gültigkeitsdatum veröffentlicht."),
                    ("Kontakt",
                     "BubbleBlack, Herausgeber von FlashTime. Bei Fragen: bubbleblack_@hotmail.com"),
                ]
            )
        }
    }
}

struct PrivacyPolicyView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @ObservedObject private var languageStore = LanguageStore.shared

    var body: some View {
        let policy = PrivacyPolicyContent.content(for: languageStore.language)

        ZStack {
            FT.Palette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                FTTopBar(title: L10n.privacyPolicy) {
                    FTBarButton(title: L10n.close, prominent: true) { dismiss() }
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(policy.updated)
                            .font(FT.Typography.body(12))
                            .foregroundStyle(FT.Palette.textTertiary)
                            .padding(.bottom, 22)

                        ForEach(Array(policy.sections.enumerated()), id: \.offset) { _, section in
                            Text(section.title)
                                .ftSectionLabel()
                                .padding(.bottom, 8)
                                .accessibilityAddTraits(.isHeader)

                            Text(section.body)
                                .font(FT.Typography.body(14))
                                .foregroundStyle(FT.Palette.textSecondary)
                                .lineSpacing(3)
                                .textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.bottom, 22)
                        }

                        Button(L10n.viewOnline) {
                            openURL(AppInfo.privacyPolicyURL)
                        }
                        .buttonStyle(.ftOutline)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                    .frame(maxWidth: 640, alignment: .leading)
                    .padding(.horizontal, 22)
                    .padding(.top, 22)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)
            }
        }
        .preferredColorScheme(FT.colorScheme)
    }
}

#Preview {
    PrivacyPolicyView()
}
