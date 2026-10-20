# Publier FlashTime sur l'App Store — marche à suivre

Ce guide suit l'ordre exact des opérations. Chaque étape dit quoi faire, où
cliquer, et pourquoi. Les textes à copier se trouvent dans
`AppStore/metadata.md`.

Vocabulaire utilisé :

- **App Store Connect** : le site d'Apple (appstoreconnect.apple.com) où l'on
  crée la fiche de l'app, envoie les versions et les soumet à la revue.
- **Build** : une version compilée de l'app, envoyée depuis Xcode. Chaque envoi
  doit porter un numéro de build différent (1, 2, 3…).
- **Archive** : le paquet final produit par Xcode, prêt à être envoyé à Apple.
- **Revue (App Review)** : le contrôle manuel d'Apple avant la mise en ligne,
  en général 24 à 48 heures.

---

## Étape 0 — Vérifier que le projet compile

1. Ouvrir `FlashTime.xcodeproj` dans Xcode.
2. En haut de la fenêtre, choisir le schéma **FlashTime** et un iPhone réel ou
   un simulateur.
3. Menu **Product › Build** (⌘B). Il ne doit y avoir aucune erreur rouge.
4. Lancer l'app (⌘R) et faire le **test de première installation** :
   supprimer d'abord l'app de l'appareil, puis la relancer depuis Xcode.
   Vérifier dans l'ordre :
   - la page de choix de langue, puis les quatre pages du tutoriel ;
   - le bouton « Continuer » qui déclenche la demande d'accès aux photos ;
   - les bulles d'aide sur l'écran principal (photo, flèches de date,
     réglages, widget) ;
   - le changement de langue dans les réglages (l'interface change aussitôt) ;
   - l'ajout du widget sur l'écran d'accueil, puis un toucher sur le widget
     (l'app doit s'ouvrir sur la photo affichée).

Changement à connaître : la version minimale d'iOS est passée de 26.5 à
**17.0**. L'app peut ainsi être installée sur beaucoup plus d'iPhone.

## Étape 1 — Mettre en ligne la politique de confidentialité

Apple exige une adresse web publique pour la politique de confidentialité et
une pour l'assistance. Les deux pages sont prêtes dans le dossier `docs/`.
**GitHub Pages** est un service gratuit de GitHub qui publie ce dossier comme
un petit site web.

1. Dans le Terminal, depuis le dossier du projet :
   ```
   git add .
   git commit -m "Préparation App Store : langues, tutoriel, confidentialité"
   git push
   ```
2. Sur github.com, ouvrir le dépôt **TentationNwaar/FlashTime**.
3. Le dépôt doit être **public** (GitHub Pages gratuit ne fonctionne qu'avec un
   dépôt public). Sinon : **Settings › General › Danger Zone › Change
   visibility › Public**.
4. **Settings › Pages** (menu de gauche). Sous *Build and deployment* :
   - *Source* : **Deploy from a branch** ;
   - *Branch* : **main**, dossier **/docs** ; cliquer **Save**.
5. Attendre une à deux minutes, puis ouvrir :
   - https://tentationnwaar.github.io/FlashTime/privacy.html
   - https://tentationnwaar.github.io/FlashTime/

Si une adresse ne s'ouvre pas, ne pas passer à la suite : l'app y renvoie
depuis ses réglages et Apple la vérifie.

## Étape 2 — Vérifier la signature dans Xcode

La **signature** prouve à Apple que l'app vient de votre compte développeur.

1. Dans Xcode, cliquer sur le projet (icône bleue en haut à gauche), puis sur
   la cible **FlashTime**, onglet **Signing & Capabilities**.
2. *Automatically manage signing* coché, *Team* : votre équipe
   (NT73585HKS). Aucune erreur affichée.
3. Section **App Groups** : `group.Maxence-Weyermann.FlashTime` coché.
4. Refaire la même vérification pour la cible **FlashTimeWidgetExtension**.

## Étape 3 — Créer la fiche dans App Store Connect

1. Aller sur appstoreconnect.apple.com › **Apps** › bouton **+** ›
   **Nouvelle app**.
2. Remplir :
   - Plateforme : **iOS** ;
   - Nom : **FlashTime** (si le nom est déjà pris : « FlashTime – Souvenirs ») ;
   - Langue principale : **English (U.S.)** ;
   - Identifiant de bundle : choisir **Maxence-Weyermann.FlashTime** dans la
     liste (il apparaît après le premier lancement sur appareil réel avec la
     signature automatique) ;
   - SKU : `flashtime-001` (référence interne libre, jamais affichée) ;
   - Accès utilisateur : **Accès complet**.
3. Cliquer **Créer**.

## Étape 4 — Informations générales de l'app

Menu de gauche, **Informations sur l'app** (App Information) :

1. Catégorie principale **Photo et vidéo**, secondaire **Style de vie**.
2. **Droits sur le contenu** : « Ne contient pas de contenu tiers ».
3. **Classification par âge** › Modifier : répondre « Aucun » ou « Non » à
   chaque question. Résultat attendu : 4+.
4. Ajouter les langues (menu en haut à droite) : French, Italian, German, et
   remplir pour chacune le sous-titre indiqué dans `metadata.md`.

Menu **Confidentialité de l'app** (App Privacy) :

1. URL de la politique : `https://tentationnwaar.github.io/FlashTime/privacy.html`.
2. **Commencer** › question « Collectez-vous des données ? » : **Non**.
3. **Publier**. La fiche affichera « Données non collectées ».

Menu **Tarifs et disponibilité** : prix **Gratuit**, tous les pays.

## Étape 5 — Captures d'écran

Apple exige des captures aux tailles suivantes, car l'app tourne sur iPhone
et sur iPad :

| Appareil | Taille | Simulateur conseillé |
|---|---|---|
| iPhone 6,9 pouces | 1320 × 2868 | iPhone 17 Pro Max |
| iPad 13 pouces | 2064 × 2752 | iPad Pro 13 pouces |

Comment faire :

1. Lancer l'app dans le simulateur concerné.
2. Glisser quelques photos depuis le Finder sur la fenêtre du simulateur :
   elles s'ajoutent à l'app Photos avec leur date d'origine.
3. Dans FlashTime, utiliser les flèches de date (ou le calendrier) pour
   afficher le jour de ces photos.
4. **⌘S** dans le simulateur enregistre une capture sur le bureau.
5. Faire 3 à 5 captures : liste des souvenirs, plein écran, widget sur l'écran
   d'accueil, réglages, page de tutoriel.

Les captures d'une langue servent pour les autres si l'on n'en fournit pas de
spécifiques.

## Étape 6 — Envoyer le build

1. Dans Xcode, choisir comme destination **Any iOS Device (arm64)**.
2. Menu **Product › Archive**. À la fin, la fenêtre *Organizer* s'ouvre.
3. Sélectionner l'archive › **Distribute App** › **App Store Connect** ›
   **Upload** › laisser les options par défaut › **Upload**.
4. Apple traite le build (15 à 30 minutes) et envoie un e-mail.

Pour chaque nouvel envoi, augmenter le numéro de build : cible **FlashTime ›
General › Identity › Build** (1 → 2 → 3…). Faire de même pour la cible du
widget, qui doit porter le même numéro.

La question sur le **chiffrement** (export compliance) ne sera pas posée :
la clé `ITSAppUsesNonExemptEncryption = NO` est déjà dans le projet, car
l'app n'utilise aucun chiffrement propre.

## Étape 7 — Remplir la version et soumettre

Menu **iOS App › 1.0 Prepare for Submission** :

1. Pour chaque langue : captures, texte promotionnel, description,
   mots-clés (tout est dans `metadata.md`).
2. URL d'assistance : `https://tentationnwaar.github.io/FlashTime/`.
3. **Build** : cliquer **+** et choisir le build envoyé à l'étape 6.
4. Copyright : `2026 Maxence Weyermann`.
5. **Informations pour la revue** : nom, téléphone, e-mail de contact ;
   décocher *Connexion requise* ; coller les notes en anglais de
   `metadata.md`.
6. **Publication de la version** : *Publier automatiquement* ou
   *Manuellement* selon votre préférence.
7. **Ajouter pour la revue**, puis **Soumettre pour la revue**.

## Étape 8 — Pendant et après la revue

- Statut *Waiting for Review* puis *In Review* : rien à faire.
- En cas de refus, Apple écrit dans le **Resolution Center** avec la règle
  concernée. Répondre au message ou corriger, renvoyer un build (numéro
  augmenté) et soumettre à nouveau.
- Motifs de refus que le projet traite déjà :
  - politique de confidentialité absente → lien dans l'app et dans la fiche ;
  - écran avant la demande d'autorisation jugé incitatif → bouton neutre
    « Continuer » ;
  - app « vide » pour le testeur → bouton « Voir les souvenirs les plus
    proches » et notes de revue explicatives ;
  - manifeste de confidentialité manquant → fichiers `PrivacyInfo.xcprivacy`
    présents dans l'app et le widget.

---

## Récapitulatif des changements apportés au projet

- **Langues** : anglais, français, italien, allemand ; choix au premier
  lancement, modifiable dans les réglages ; le widget suit la langue choisie.
  La demande d'accès aux photos du système reste dans la langue de l'iPhone
  (comportement imposé par iOS), elle aussi traduite dans les quatre langues.
- **Tutoriel** : pages d'accueil, puis bulles pas à pas sur l'écran principal ;
  « Revoir le tutoriel » dans les réglages.
- **Ergonomie** : navigation de jour en jour et calendrier ; recherche des
  souvenirs les plus proches ; plein écran avec balayage, partage et masquage ;
  fermeture par glissement vers le bas ; grille adaptée à l'iPad ; retours
  haptiques ; libellés VoiceOver ; réglages enregistrés automatiquement à la
  fermeture ; toucher sur le widget ouvrant la photo affichée ; demande de note
  discrète après quelques jours d'utilisation.
- **Conformité** : politique de confidentialité (app + web), page
  d'assistance, manifestes de confidentialité, déclaration de chiffrement,
  nom affiché « FlashTime » pour l'app et le widget, catégorie Photo.
