//
//  Localization.swift
//  FlashTime — code partagé entre l'app et le widget
//
//  Langue de l'interface, choisie au premier lancement et modifiable dans les
//  réglages. Elle est stockée dans l'App Group : le widget l'applique lui aussi.
//
//  Les textes sont définis ici en Swift plutôt que dans un catalogue de
//  chaînes : chaque entrée fournit obligatoirement ses quatre traductions,
//  donc un oubli provoque une erreur de compilation, et la langue peut changer
//  à chaud sans relancer l'app (ce que la localisation système ne permet pas).
//

import Foundation

// MARK: - Langue

nonisolated enum AppLanguage: String, CaseIterable, Identifiable, Sendable {

    case english = "en"
    case french = "fr"
    case italian = "it"
    case german = "de"

    var id: String { rawValue }

    /// Nom de la langue dans la langue elle-même : c'est ce que l'utilisateur
    /// cherche dans une liste, quelle que soit la langue affichée.
    var nativeName: String {
        switch self {
        case .english: return "English"
        case .french: return "Français"
        case .italian: return "Italiano"
        case .german: return "Deutsch"
        }
    }

    /// Locale utilisée pour les dates : langue choisie + région de l'appareil,
    /// ce qui donne par exemple « 20. Oktober » en Suisse alémanique.
    var locale: Locale {
        if let region = Locale.current.region?.identifier {
            return Locale(identifier: "\(rawValue)_\(region)")
        }
        return Locale(identifier: rawValue)
    }

    // MARK: Stockage

    private static let key = "app.language"

    /// Langue active : le choix enregistré, sinon la langue de l'appareil.
    static var current: AppLanguage {
        if let raw = AppGroup.defaults.string(forKey: key),
           let language = AppLanguage(rawValue: raw) {
            return language
        }
        return deviceDefault
    }

    /// Première langue de l'appareil prise en charge, sinon l'anglais.
    static var deviceDefault: AppLanguage {
        for identifier in Locale.preferredLanguages {
            let code = Locale(identifier: identifier).language.languageCode?.identifier
                ?? String(identifier.prefix(2))
            if let language = AppLanguage(rawValue: code) {
                return language
            }
        }
        return .english
    }

    static func save(_ language: AppLanguage) {
        AppGroup.defaults.set(language.rawValue, forKey: key)
    }
}

// MARK: - Textes

nonisolated enum L10n {

    /// Sélectionne la traduction correspondant à la langue active.
    /// Ordre fixe des paramètres : anglais, français, italien, allemand.
    static func tr(_ en: String, _ fr: String, _ it: String, _ de: String) -> String {
        switch AppLanguage.current {
        case .english: return en
        case .french: return fr
        case .italian: return it
        case .german: return de
        }
    }

    // MARK: Généraux

    static var appName: String { "FlashTime" }

    // MARK: Dates

    /// « 20 octobre ».
    static func dayMonth(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.wide).locale(AppLanguage.current.locale))
    }

    /// « mardi 20 octobre », avec l'année si elle diffère de l'année en cours.
    static func navigatorDate(_ date: Date, calendar: Calendar = .current) -> String {
        let sameYear = calendar.component(.year, from: date) == calendar.component(.year, from: Date())
        let style = Date.FormatStyle.dateTime.weekday(.wide).day().month(.wide)
        return date.formatted(
            (sameYear ? style : style.year()).locale(AppLanguage.current.locale)
        )
    }

    /// « 4 août 2016 ».
    static func fullDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.wide).year().locale(AppLanguage.current.locale))
    }

    /// « Il y a 10 ans ».
    static func yearsAgo(_ n: Int) -> String {
        n == 1
            ? tr("1 year ago", "Il y a 1 an", "1 anno fa", "Vor 1 Jahr")
            : tr("\(n) years ago", "Il y a \(n) ans", "\(n) anni fa", "Vor \(n) Jahren")
    }

    /// « 10 ans », pour les réglages.
    static func years(_ n: Int) -> String {
        n == 1
            ? tr("1 year", "1 an", "1 anno", "1 Jahr")
            : tr("\(n) years", "\(n) ans", "\(n) anni", "\(n) Jahre")
    }

    static func memoriesCount(_ n: Int) -> String {
        n == 1
            ? tr("1 memory", "1 souvenir", "1 ricordo", "1 Erinnerung")
            : tr("\(n) memories", "\(n) souvenirs", "\(n) ricordi", "\(n) Erinnerungen")
    }

    static func photosCount(_ n: Int) -> String {
        n == 1
            ? tr("1 photo", "1 photo", "1 foto", "1 Foto")
            : tr("\(n) photos", "\(n) photos", "\(n) foto", "\(n) Fotos")
    }

    static var selection: String { tr("Selection", "Sélection", "Selezione", "Auswahl") }
    static var selectAll: String { tr("All", "Tout", "Tutte", "Alle") }
    static var done: String { tr("Done", "Terminé", "Fine", "Fertig") }
    static var close: String { tr("Close", "Fermer", "Chiudi", "Schließen") }
    static var share: String { tr("Share", "Partager", "Condividi", "Teilen") }
    static var today: String { tr("Today", "Aujourd'hui", "Oggi", "Heute") }
    static var next: String { tr("Next", "Suivant", "Avanti", "Weiter") }
    static var back: String { tr("Back", "Retour", "Indietro", "Zurück") }
    static var skip: String { tr("Skip", "Passer", "Salta", "Überspringen") }
    static var gotIt: String { tr("Got it", "Compris", "Ho capito", "Verstanden") }
    static var getStarted: String { tr("Get started", "Commencer", "Inizia", "Los geht's") }
    static var continueLabel: String { tr("Continue", "Continuer", "Continua", "Weiter") }
    static var searching: String { tr("Searching", "Recherche en cours", "Ricerca in corso", "Suche läuft") }

    // MARK: Liste et sélection

    static var hideFromWidget: String {
        tr("Hide from widget", "Masquer du widget", "Nascondi dal widget", "Im Widget ausblenden")
    }
    static var showInWidget: String {
        tr("Show in widget", "Afficher dans le widget", "Mostra nel widget", "Im Widget anzeigen")
    }
    static var hiddenFromWidget: String {
        tr("Hidden from widget", "Masquée du widget", "Nascosta dal widget", "Im Widget ausgeblendet")
    }
    static var selectSeveral: String {
        tr("Select several", "Sélectionner plusieurs", "Seleziona più foto", "Mehrere auswählen")
    }
    static var previousDay: String { tr("Previous day", "Jour précédent", "Giorno precedente", "Vorheriger Tag") }
    static var nextDay: String { tr("Next day", "Jour suivant", "Giorno successivo", "Nächster Tag") }
    static var chooseDate: String { tr("Choose a date", "Choisir une date", "Scegli una data", "Datum wählen") }

    static func noMemoriesTitle(_ date: String) -> String {
        tr("No memories\non \(date)",
           "Aucun souvenir\nle \(date)",
           "Nessun ricordo\nil \(date)",
           "Keine Erinnerungen\nam \(date)")
    }
    static var noMemoriesMessage: String {
        tr("Your library has no photo taken on this day in a previous year. Browse other days with the arrows.",
           "Votre photothèque ne contient aucune photo prise ce jour-là une année précédente. Parcourez d'autres jours avec les flèches.",
           "La tua libreria non contiene foto scattate in questo giorno negli anni precedenti. Sfoglia altri giorni con le frecce.",
           "Ihre Mediathek enthält kein Foto, das in einem früheren Jahr an diesem Tag aufgenommen wurde. Blättern Sie mit den Pfeilen durch andere Tage.")
    }
    static var showNearest: String {
        tr("Show nearest memories", "Voir les souvenirs les plus proches",
           "Mostra i ricordi più vicini", "Nächste Erinnerungen anzeigen")
    }
    static var nothingNearby: String {
        tr("No memories found in the surrounding months.",
           "Aucun souvenir trouvé dans les mois voisins.",
           "Nessun ricordo trovato nei mesi vicini.",
           "In den umliegenden Monaten wurden keine Erinnerungen gefunden.")
    }

    // MARK: Accès aux photos

    static var welcomeTitle: String {
        tr("Your memories,\nevery day", "Vos souvenirs,\nchaque jour",
           "I tuoi ricordi,\nogni giorno", "Ihre Erinnerungen,\njeden Tag")
    }
    static var accessMessage: String {
        tr("To find your memories, FlashTime needs to read the dates of your photos. Everything stays on your device.",
           "Pour retrouver vos souvenirs, FlashTime doit lire les dates de vos photos. Tout reste sur votre appareil.",
           "Per trovare i tuoi ricordi, FlashTime deve leggere le date delle tue foto. Tutto resta sul tuo dispositivo.",
           "Um Ihre Erinnerungen zu finden, muss FlashTime die Aufnahmedaten Ihrer Fotos lesen. Alles bleibt auf Ihrem Gerät.")
    }
    static var deniedTitle: String { tr("Access denied", "Accès refusé", "Accesso negato", "Zugriff verweigert") }
    static var deniedMessage: String {
        tr("FlashTime needs to read the dates of your photos to find your memories. Access can be changed in the system settings.",
           "FlashTime a besoin de lire les dates de vos photos pour retrouver vos souvenirs. L'autorisation se règle dans les réglages du système.",
           "FlashTime deve leggere le date delle tue foto per trovare i tuoi ricordi. L'accesso si modifica nelle impostazioni di sistema.",
           "FlashTime muss die Aufnahmedaten Ihrer Fotos lesen, um Ihre Erinnerungen zu finden. Der Zugriff lässt sich in den Systemeinstellungen ändern.")
    }
    static var openSettings: String {
        tr("Open Settings", "Ouvrir les réglages", "Apri Impostazioni", "Einstellungen öffnen")
    }

    // MARK: Réglages

    static var settings: String { tr("Settings", "Réglages", "Impostazioni", "Einstellungen") }
    static var timeWindow: String { tr("Time window", "Fenêtre de temps", "Intervallo di tempo", "Zeitraum") }
    static var from: String { tr("From", "À partir de", "Da", "Ab") }
    static var upTo: String { tr("Up to", "Jusqu'à", "Fino a", "Bis") }

    static func windowFootnote(min: Int, max: Int) -> String {
        if min == max {
            let en = min == 1 ? "1 year" : "\(min) years"
            let fr = min == 1 ? "1 an" : "\(min) ans"
            let it = min == 1 ? "1 anno" : "\(min) anni"
            let de = min == 1 ? "1 Jahr" : "\(min) Jahren"
            return tr("FlashTime looks for photos taken on the same day, \(en) ago.",
                      "FlashTime cherche les photos prises le même jour, il y a \(fr).",
                      "FlashTime cerca le foto scattate lo stesso giorno, \(it) fa.",
                      "FlashTime sucht Fotos vom selben Tag, aufgenommen vor \(de).")
        }
        return tr("FlashTime looks for photos taken on the same day, \(min) to \(max) years ago.",
                  "FlashTime cherche les photos prises le même jour, il y a \(min) à \(max) ans.",
                  "FlashTime cerca le foto scattate lo stesso giorno, da \(min) a \(max) anni fa.",
                  "FlashTime sucht Fotos vom selben Tag, aufgenommen vor \(min) bis \(max) Jahren.")
    }

    static var filters: String { tr("Filters", "Filtres", "Filtri", "Filter") }
    static var excludeScreenshots: String {
        tr("Exclude screenshots", "Exclure les captures d'écran", "Escludi gli screenshot", "Bildschirmfotos ausschließen")
    }
    static var hiddenPhotos: String { tr("Hidden photos", "Photos masquées", "Foto nascoste", "Ausgeblendete Fotos") }
    static func hiddenFootnote(_ n: Int) -> String {
        n == 1
            ? tr("1 photo is hidden from the widget. It stays visible in the app, dimmed.",
                 "1 photo est écartée du widget. Elle reste visible dans l'app, grisée.",
                 "1 foto è nascosta dal widget. Resta visibile nell'app, attenuata.",
                 "1 Foto ist im Widget ausgeblendet. In der App bleibt es abgedunkelt sichtbar.")
            : tr("\(n) photos are hidden from the widget. They stay visible in the app, dimmed.",
                 "\(n) photos sont écartées du widget. Elles restent visibles dans l'app, grisées.",
                 "\(n) foto sono nascoste dal widget. Restano visibili nell'app, attenuate.",
                 "\(n) Fotos sind im Widget ausgeblendet. In der App bleiben sie abgedunkelt sichtbar.")
    }
    static var showAllAgain: String {
        tr("Show all again", "Tout réafficher", "Mostra di nuovo tutte", "Alle wieder anzeigen")
    }
    static var limitedFootnote: String {
        tr("FlashTime can only see a selection of your photos. Extend it to find more memories.",
           "FlashTime n'a accès qu'à une sélection de photos. Élargissez-la pour retrouver davantage de souvenirs.",
           "FlashTime vede solo una selezione delle tue foto. Ampliala per trovare più ricordi.",
           "FlashTime sieht nur eine Auswahl Ihrer Fotos. Erweitern Sie sie, um mehr Erinnerungen zu finden.")
    }
    static var chooseMorePhotos: String {
        tr("Choose more photos", "Choisir davantage de photos", "Scegli altre foto", "Weitere Fotos auswählen")
    }
    static var language: String { tr("Language", "Langue", "Lingua", "Sprache") }
    static var help: String { tr("Help", "Aide", "Aiuto", "Hilfe") }
    static var replayTutorial: String {
        tr("Replay the tutorial", "Revoir le tutoriel", "Rivedi il tutorial", "Tutorial erneut ansehen")
    }
    static var about: String { tr("About", "À propos", "Informazioni", "Über") }
    static var privacyPolicy: String {
        tr("Privacy policy", "Politique de confidentialité", "Informativa sulla privacy", "Datenschutzerklärung")
    }
    static var contactSupport: String {
        tr("Contact support", "Contacter le support", "Contatta l'assistenza", "Support kontaktieren")
    }
    static var systemSettings: String {
        tr("App system settings", "Réglages système de l'app", "Impostazioni di sistema dell'app", "Systemeinstellungen der App")
    }
    static func version(_ version: String, _ build: String) -> String {
        tr("Version \(version) (\(build))", "Version \(version) (\(build))",
           "Versione \(version) (\(build))", "Version \(version) (\(build))")
    }
    static var viewOnline: String {
        tr("View online version", "Voir la version en ligne",
           "Visualizza la versione online", "Online-Version ansehen")
    }

    // MARK: Tutoriel d'accueil

    static var chooseLanguageTitle: String {
        tr("Choose your language", "Choisissez votre langue", "Scegli la lingua", "Sprache wählen")
    }
    static var chooseLanguageFootnote: String {
        tr("You can change it at any time in the settings.",
           "Vous pourrez la modifier à tout moment dans les réglages.",
           "Puoi cambiarla in qualsiasi momento nelle impostazioni.",
           "Sie können sie jederzeit in den Einstellungen ändern.")
    }

    static var introMemoriesTitle: String { welcomeTitle }
    static var introMemoriesBody: String {
        tr("FlashTime finds the photos you took on this very day in previous years, and groups them by age.",
           "FlashTime retrouve les photos prises ce même jour les années précédentes, et les regroupe par ancienneté.",
           "FlashTime ritrova le foto scattate in questo stesso giorno negli anni precedenti e le raggruppa per anno.",
           "FlashTime findet die Fotos, die Sie an diesem Tag in früheren Jahren aufgenommen haben, und ordnet sie nach Alter.")
    }
    static var introWidgetTitle: String {
        tr("On your\nHome Screen", "Sur votre\nécran d'accueil", "Nella tua\nschermata Home", "Auf Ihrem\nHome-Bildschirm")
    }
    static var introWidgetBody: String {
        tr("Add the FlashTime widget: a different memory appears throughout the day, and its arrows let you browse the other photos of the day.",
           "Ajoutez le widget FlashTime : un souvenir différent apparaît au fil de la journée, et ses flèches font défiler les autres photos du jour.",
           "Aggiungi il widget FlashTime: un ricordo diverso appare durante la giornata e le sue frecce fanno scorrere le altre foto del giorno.",
           "Fügen Sie das FlashTime-Widget hinzu: Im Laufe des Tages erscheint eine andere Erinnerung, und mit den Pfeilen blättern Sie durch die übrigen Fotos des Tages.")
    }
    static var introCurateTitle: String {
        tr("You decide", "Vous décidez", "Decidi tu", "Sie entscheiden")
    }
    static var introCurateBody: String {
        tr("Touch and hold a photo to hide it from the widget. Browse other days and set the time window as you like.",
           "Un appui long sur une photo l'écarte du widget. Parcourez d'autres jours et réglez la période comme vous le souhaitez.",
           "Tieni premuta una foto per nasconderla dal widget. Sfoglia altri giorni e regola il periodo come preferisci.",
           "Halten Sie ein Foto gedrückt, um es im Widget auszublenden. Blättern Sie durch andere Tage und passen Sie den Zeitraum an.")
    }
    static var introPrivacyTitle: String {
        tr("Private\nby design", "Privé\npar conception", "Privato\nper scelta", "Privat\nvon Grund auf")
    }
    static var introPrivacyBody: String {
        tr("Your photos never leave your device. No account, no server, no tracking.",
           "Vos photos ne quittent jamais votre appareil. Ni compte, ni serveur, ni pistage.",
           "Le tue foto non lasciano mai il dispositivo. Nessun account, nessun server, nessun tracciamento.",
           "Ihre Fotos verlassen nie Ihr Gerät. Kein Konto, kein Server, kein Tracking.")
    }

    // MARK: Bulles d'aide

    static var coachOpenTitle: String { tr("Your memories", "Vos souvenirs", "I tuoi ricordi", "Ihre Erinnerungen") }
    static var coachOpenBody: String {
        tr("Here are the photos taken on this same date in previous years. Tap a photo to enlarge it, then swipe to see the next one.",
           "Voici les photos prises à cette même date les années précédentes. Touchez une photo pour l'agrandir, puis balayez pour passer à la suivante.",
           "Ecco le foto scattate in questa stessa data negli anni precedenti. Tocca una foto per ingrandirla, poi scorri per vedere la successiva.",
           "Hier sehen Sie die Fotos, die in früheren Jahren am selben Datum entstanden sind. Tippen Sie auf ein Foto, um es zu vergrößern, und wischen Sie dann zum nächsten.")
    }
    static var coachHideTitle: String {
        tr("Choose what the widget shows", "Choisissez ce qu'affiche le widget",
           "Scegli cosa mostra il widget", "Bestimmen Sie den Widget-Inhalt")
    }
    static var coachHideBody: String {
        tr("Touch and hold a photo to hide it from the widget, or to select several at once. Hidden photos stay here, dimmed.",
           "Un appui long sur une photo permet de la masquer du widget, ou d'en sélectionner plusieurs. Les photos masquées restent ici, grisées.",
           "Tieni premuta una foto per nasconderla dal widget o per selezionarne più di una. Le foto nascoste restano qui, attenuate.",
           "Halten Sie ein Foto gedrückt, um es im Widget auszublenden oder mehrere auszuwählen. Ausgeblendete Fotos bleiben hier abgedunkelt.")
    }
    static var coachDayTitle: String {
        tr("Explore other days", "Explorez d'autres jours", "Esplora altri giorni", "Andere Tage entdecken")
    }
    static var coachDayBody: String {
        tr("Use the arrows to move from day to day, or tap the date to pick one directly.",
           "Les flèches font défiler les jours. Touchez la date pour en choisir une directement.",
           "Usa le frecce per passare da un giorno all'altro, oppure tocca la data per sceglierne una.",
           "Mit den Pfeilen wechseln Sie den Tag. Tippen Sie auf das Datum, um direkt eines zu wählen.")
    }
    static var coachSettingsTitle: String { settings }
    static var coachSettingsBody: String {
        tr("Adjust the time window, exclude screenshots, change the language or replay this tutorial.",
           "Réglez la fenêtre de temps, excluez les captures d'écran, changez de langue ou revoyez ce tutoriel.",
           "Regola l'intervallo di tempo, escludi gli screenshot, cambia lingua o rivedi questo tutorial.",
           "Passen Sie den Zeitraum an, schließen Sie Bildschirmfotos aus, ändern Sie die Sprache oder sehen Sie dieses Tutorial erneut.")
    }
    static var coachWidgetTitle: String {
        tr("Add the widget", "Ajoutez le widget", "Aggiungi il widget", "Widget hinzufügen")
    }
    static var coachWidgetBody: String {
        tr("On the Home Screen, touch and hold an empty area, tap Edit then Add Widget (or “+”), search for FlashTime and choose a size.",
           "Sur l'écran d'accueil, maintenez le doigt sur une zone vide, touchez Modifier puis Ajouter un widget (ou « + »), cherchez FlashTime et choisissez une taille.",
           "Nella schermata Home, tieni premuta un'area vuota, tocca Modifica e poi Aggiungi widget (o «+»), cerca FlashTime e scegli una dimensione.",
           "Halten Sie auf dem Home-Bildschirm eine freie Stelle gedrückt, tippen Sie auf Bearbeiten und dann auf Widget hinzufügen (oder „+“), suchen Sie FlashTime und wählen Sie eine Größe.")
    }
    static var howToAddWidget: String {
        tr("How to add the widget", "Ajouter le widget", "Come aggiungere il widget", "Widget hinzufügen")
    }

    // MARK: Premium

    static var premiumName: String { "FlashTime Premium" }
    static var premiumTagline: String {
        tr("One purchase, yours forever. No subscription.",
           "Un seul achat, à vous pour toujours. Sans abonnement.",
           "Un solo acquisto, tuo per sempre. Nessun abbonamento.",
           "Einmal kaufen, für immer behalten. Kein Abo.")
    }
    static var featureStylesTitle: String {
        tr("Widget styles", "Styles de widget", "Stili del widget", "Widget-Stile")
    }
    static var featureStylesBody: String {
        tr("Instant print, photo only or fine frame.",
           "Tirage instantané, photo seule ou filet fin.",
           "Stampa istantanea, solo foto o cornice sottile.",
           "Sofortbild, nur Foto oder feiner Rahmen.")
    }
    static var featureFavoritesTitle: String { tr("Favourites", "Favoris", "Preferiti", "Favoriten") }
    static var featureFavoritesBody: String {
        tr("Heart your best memories: the widget shows them twice as often.",
           "Mettez un cœur à vos plus beaux souvenirs : le widget les montre deux fois plus souvent.",
           "Metti un cuore ai ricordi più belli: il widget li mostra il doppio delle volte.",
           "Markieren Sie Ihre schönsten Erinnerungen: Das Widget zeigt sie doppelt so oft.")
    }
    static var featureThemesTitle: String { tr("Colour themes", "Thèmes de couleur", "Temi di colore", "Farbthemen") }
    static var featureThemesBody: String {
        tr("Cream, pure black or midnight blue.",
           "Crème, noir pur ou bleu nuit.",
           "Crema, nero puro o blu notte.",
           "Creme, Tiefschwarz oder Nachtblau.")
    }
    static var featureVideosTitle: String {
        tr("Videos and Live Photos", "Vidéos et Live Photos", "Video e Live Photo", "Videos und Live Photos")
    }
    static var featureVideosBody: String {
        tr("Relive the videos of the day and bring your Live Photos to life.",
           "Revoyez les vidéos du jour et animez vos Live Photos.",
           "Rivedi i video del giorno e anima le tue Live Photo.",
           "Sehen Sie die Videos des Tages und erwecken Sie Ihre Live Photos zum Leben.")
    }
    static func unlockFor(_ price: String) -> String {
        tr("Unlock for \(price)", "Débloquer pour \(price)", "Sblocca per \(price)", "Für \(price) freischalten")
    }
    static var premiumActive: String {
        tr("Premium is active. Thank you!", "Premium est activé. Merci !", "Premium è attivo. Grazie!", "Premium ist aktiv. Danke!")
    }
    static var discoverPremium: String {
        tr("Discover Premium", "Découvrir Premium", "Scopri Premium", "Premium entdecken")
    }
    static var restorePurchases: String {
        tr("Restore purchases", "Restaurer les achats", "Ripristina acquisti", "Käufe wiederherstellen")
    }
    static var restoreSuccess: String {
        tr("Your purchase has been restored.", "Votre achat a été restauré.", "Il tuo acquisto è stato ripristinato.", "Ihr Kauf wurde wiederhergestellt.")
    }
    static var restoreNothing: String {
        tr("No previous purchase was found for this Apple Account.",
           "Aucun achat précédent n'a été trouvé pour ce compte Apple.",
           "Nessun acquisto precedente trovato per questo Account Apple.",
           "Für diesen Apple Account wurde kein früherer Kauf gefunden.")
    }
    static var purchaseFailed: String {
        tr("The purchase could not be completed. Please try again.",
           "L'achat n'a pas pu aboutir. Veuillez réessayer.",
           "Non è stato possibile completare l'acquisto. Riprova.",
           "Der Kauf konnte nicht abgeschlossen werden. Bitte versuchen Sie es erneut.")
    }
    static var storeUnavailable: String {
        tr("The App Store is unavailable right now.",
           "L'App Store est indisponible pour le moment.",
           "L'App Store non è al momento disponibile.",
           "Der App Store ist derzeit nicht verfügbar.")
    }
    static var supportTitle: String {
        tr("Support FlashTime", "Soutenir FlashTime", "Sostieni FlashTime", "FlashTime unterstützen")
    }
    static var supportBody: String {
        tr("FlashTime is made by an independent developer. A tip helps keep it ad-free.",
           "FlashTime est conçu par un développeur indépendant. Un pourboire l'aide à rester sans publicité.",
           "FlashTime è realizzata da uno sviluppatore indipendente. Una mancia la aiuta a restare senza pubblicità.",
           "FlashTime wird von einem unabhängigen Entwickler gemacht. Ein Trinkgeld hilft, sie werbefrei zu halten.")
    }
    static var tipSmall: String { tr("Small thanks", "Petit merci", "Piccolo grazie", "Kleines Danke") }
    static var tipMedium: String { tr("Big thanks", "Grand merci", "Grande grazie", "Großes Danke") }
    static var tipLarge: String { tr("Huge thanks", "Immense merci", "Enorme grazie", "Riesiges Danke") }
    static var tipThanks: String {
        tr("Thank you so much for your support!",
           "Merci beaucoup pour votre soutien !",
           "Grazie mille per il tuo sostegno!",
           "Vielen Dank für Ihre Unterstützung!")
    }
    static var purchaseFootnote: String {
        tr("Payment is handled by Apple and charged to your Apple Account. Tips are optional and unlock nothing.",
           "Le paiement est géré par Apple et débité de votre compte Apple. Les pourboires sont facultatifs et ne débloquent rien.",
           "Il pagamento è gestito da Apple e addebitato sul tuo Account Apple. Le mance sono facoltative e non sbloccano nulla.",
           "Die Zahlung wird von Apple abgewickelt und Ihrem Apple Account belastet. Trinkgelder sind freiwillig und schalten nichts frei.")
    }
    static var appearance: String { tr("Appearance", "Apparence", "Aspetto", "Darstellung") }
    static var theme: String { tr("Theme", "Thème", "Tema", "Thema") }
    static var widgetStyle: String { tr("Widget style", "Style du widget", "Stile del widget", "Widget-Stil") }
    static var includeVideos: String {
        tr("Show videos of the day", "Afficher les vidéos du jour", "Mostra i video del giorno", "Videos des Tages anzeigen")
    }
    static var addFavorite: String {
        tr("Add to favourites", "Ajouter aux favoris", "Aggiungi ai preferiti", "Zu Favoriten hinzufügen")
    }
    static var removeFavorite: String {
        tr("Remove from favourites", "Retirer des favoris", "Rimuovi dai preferiti", "Aus Favoriten entfernen")
    }
    static var favorites: String { featureFavoritesTitle }
    static var noFavoritesTitle: String {
        tr("No favourites\nyet", "Pas encore\nde favoris", "Ancora nessun\npreferito", "Noch keine\nFavoriten")
    }
    static var noFavoritesBody: String {
        tr("Touch and hold a memory, or use the heart in full screen, to add it here.",
           "Faites un appui long sur un souvenir, ou touchez le cœur en plein écran, pour l'ajouter ici.",
           "Tieni premuto un ricordo, o tocca il cuore a schermo intero, per aggiungerlo qui.",
           "Halten Sie eine Erinnerung gedrückt oder tippen Sie im Vollbild auf das Herz, um sie hier hinzuzufügen.")
    }
    static var premiumFeature: String {
        tr("Premium feature", "Fonction Premium", "Funzione Premium", "Premium-Funktion")
    }

    // MARK: Widget

    static var previousMemory: String {
        tr("Previous memory", "Souvenir précédent", "Ricordo precedente", "Vorherige Erinnerung")
    }
    static var nextMemory: String {
        tr("Next memory", "Souvenir suivant", "Ricordo successivo", "Nächste Erinnerung")
    }
    static var widgetName: String { tr("Memories", "Souvenirs", "Ricordi", "Erinnerungen") }
    static var widgetDescription: String {
        tr("Photos taken on this day in past years.",
           "Les photos prises le même jour, les années passées.",
           "Le foto scattate in questo giorno negli anni passati.",
           "Fotos von diesem Tag aus vergangenen Jahren.")
    }
    static var widgetEmptyTitle: String { tr("No memory", "Pas de souvenir", "Nessun ricordo", "Keine Erinnerung") }
    static var widgetEmptyDetail: String {
        tr("No photo taken on this day in past years.",
           "Aucune photo prise un tel jour les années passées.",
           "Nessuna foto scattata in questo giorno negli anni passati.",
           "Kein Foto von diesem Tag aus vergangenen Jahren.")
    }
    static var widgetAccessTitle: String {
        tr("Access needed", "Accès requis", "Accesso richiesto", "Zugriff erforderlich")
    }
    static var widgetAccessDetail: String {
        tr("Open FlashTime to allow access to your photos.",
           "Ouvrez FlashTime pour autoriser l'accès à vos photos.",
           "Apri FlashTime per consentire l'accesso alle foto.",
           "Öffnen Sie FlashTime, um den Zugriff auf Ihre Fotos zu erlauben.")
    }
    static var widgetPlaceholderDetail: String {
        tr("Your memories of the day.", "Vos souvenirs du jour.", "I tuoi ricordi del giorno.", "Ihre Erinnerungen des Tages.")
    }
}

// MARK: - Informations publiques

/// Coordonnées et liens publiés avec l'app (page App Store, politique de
/// confidentialité). À tenir à jour si l'adresse ou le dépôt changent.
nonisolated enum AppInfo {
    static let supportEmail = "bubbleblack_@hotmail.com"
    static let websiteURL = URL(string: "https://tentationnwaar.github.io/FlashTime/")!
    static let privacyPolicyURL = URL(string: "https://tentationnwaar.github.io/FlashTime/privacy.html")!

    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
    static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
}
