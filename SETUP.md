# FlashTime — mise en place dans Xcode

> Pour la publication sur l'App Store, voir `PUBLICATION.md`.

Le code est écrit. Il reste à créer la target widget et à relier les fichiers,
ce qui se fait dans l'interface d'Xcode (5 minutes).

## Ce qui existe déjà

```
FlashTime/                     ← target app (fichiers auto-inclus)
  FlashTimeApp.swift
  ContentView.swift
  MemoriesViewModel.swift
  MemoryThumbnail.swift
  MemoryDetailView.swift
  SettingsView.swift
Shared/                        ← compilé par les DEUX targets
  AppGroup.swift
  MemoryPhoto.swift
  PhotoAccess.swift
  MemoriesFetcher.swift
  Theme.swift                  ← direction artistique (palette, typo, composants)
FlashTimeWidgetSources/        ← à déplacer dans la target widget
  FlashTimeWidgetBundle.swift
  FlashTimeWidget.swift
  MemoryWidgetView.swift
```

Le projet utilise les groupes synchronisés d'Xcode 16+ : tout fichier posé dans
un dossier déjà référencé est automatiquement compilé.

---

## 1. Créer la target widget

`File > New > Target… > iOS > Widget Extension`

- Product Name : **FlashTimeWidget**
- Décocher **Include Live Activity**
- Décocher **Include Configuration App Intent**
- Finish, puis **Activate** le schéma proposé.

## 2. Remplacer les fichiers du template

Dans le navigateur, sous le dossier `FlashTimeWidget` créé par Xcode, supprimer
(*Move to Trash*) tous les `.swift` générés — typiquement
`FlashTimeWidget.swift`, `FlashTimeWidgetBundle.swift`, et le cas échéant
`AppIntent.swift` ou `FlashTimeWidgetControl.swift`.

Puis, dans le Finder, déplacer les trois fichiers de `FlashTimeWidgetSources/`
vers le dossier `FlashTimeWidget/`. Ils apparaissent aussitôt dans Xcode.
Le dossier `FlashTimeWidgetSources` peut ensuite être supprimé.

## 3. Partager le dossier `Shared`

Glisser le dossier `Shared` depuis le Finder vers la racine du projet dans le
navigateur Xcode.

- Cocher **Create folder references** / laisser le mode dossier synchronisé.
- Sélectionner le dossier `Shared`, ouvrir l'inspecteur de fichiers (⌥⌘1) et
  cocher **les deux targets** : `FlashTime` **et** `FlashTimeWidgetExtension`.

C'est l'étape critique : sans elle, le widget ne compile pas (`MemoriesFetcher`
introuvable).

## 4. Activer l'App Group sur les deux targets

Pour `FlashTime` puis pour `FlashTimeWidgetExtension` :

`Signing & Capabilities > + Capability > App Groups > +`

Identifiant exact :

```
group.Maxence-Weyermann.FlashTime
```

Il doit être identique des deux côtés et correspondre à `AppGroup.identifier`
dans `Shared/AppGroup.swift`. Il sert à partager les réglages (fenêtre
d'années, exclusion des captures d'écran) entre l'app et le widget.

## 5. Permission photothèque

Déjà configurée : la clé `NSPhotoLibraryUsageDescription` a été ajoutée aux
réglages de build de la target app (Debug et Release). Rien à faire.

L'extension widget n'a pas besoin de sa propre clé : une extension hérite de
l'autorisation accordée à son app conteneur.

## 6. Lancer

Choisir le schéma **FlashTime**, exécuter sur un **appareil réel**. Le
simulateur ne contient que quelques photos de démonstration, dont les dates ne
tomberont presque jamais sur le jour courant.

Pour tester le widget : appui long sur l'écran d'accueil > `+` > FlashTime >
choisir la taille. Les quatre tailles (petit, moyen, grand, très grand sur iPad)
sont prises en charge.

---

## Comment ça marche

**Recherche des souvenirs** (`Shared/MemoriesFetcher.swift`)
Une requête PhotoKit avec un prédicat `OU` sur une plage `[00:00, 24:00[` par
année ciblée (1 à 30 ans en arrière par défaut). Seules les métadonnées sont
lues : c'est peu coûteux, donc exécutable depuis l'extension.

**Le widget interroge PhotoKit directement**
Pas de cache d'images dans l'App Group, pas de tâche d'arrière-plan : le widget
reconstruit sa timeline lui-même, donc il ne se périme jamais même si l'app
n'est pas ouverte pendant des semaines. Une seule image est décodée à la fois,
à la taille exacte du widget, ce qui reste sous la limite mémoire d'environ
30 Mo des extensions WidgetKit.

**Changement de jour sans ouvrir l'app**
Chaque timeline se termine par une entrée datée de minuit qui contient déjà le
premier souvenir du lendemain, image comprise. Le widget bascule donc à la bonne
date même si iOS ne réveille pas l'extension à cet instant — ce qui est le cas
ordinaire pendant la nuit. Aucune entrée ne franchit minuit, sans quoi le
libellé « il y a X ans » deviendrait faux. La reconstruction complète est
programmée deux minutes après le changement de date.

**Photos écartées**
Un appui long sur une vignette propose de la masquer, ou d'entrer en sélection
multiple. Les identifiants écartés sont stockés dans les réglages partagés
(`HiddenPhotos`) et filtrés à la construction de la timeline. Les photos restent
visibles dans l'app, assourdies et marquées d'un œil barré ; les réglages
permettent de tout réafficher d'un coup.

**Rotation des photos**
Les souvenirs du jour sont mélangés avec un générateur pseudo-aléatoire dont la
graine est la date : l'ordre est stable sur la journée, différent chaque jour.
Chaque timeline contient 5 entrées espacées de 30 minutes, et l'index de départ
est déduit de l'heure courante pour que le cycle continue d'une reconstruction
à la suivante. Rechargement forcé à minuit, quand les souvenirs changent.

**Titre affiché**
`MemoryPhoto.title` → « Il y a 10 ans », avec la date complète sous-titrée sur
les tailles moyennes et grandes.

## Direction artistique

Tout est centralisé dans `Shared/Theme.swift`.

**Palette** — anthracite neutre (`#262626`) plutôt que noir pur, bandeaux en
`#343434`, filets en `#454545`, texte en blanc légèrement chaud (`#F2F0EC`).
Le bleu de l'icône (`#0770FE`) n'apparaît que sur les éléments actifs : bouton
principal, action « Enregistrer », interrupteurs. Les photos sont la seule autre
source de couleur.

**Typographie** — serif système (New York) en petites capitales très espacées
pour les titres, sections et boutons ; sans-serif pour les paragraphes, qui
restent plus lisibles ainsi. L'interlettrage est la signature visuelle : 4 pt
sur les titres, 2,6 pt sur les libellés.

**Formes** — aucun arrondi hors du logo. Boutons encadrés d'un filet d'1 pt sans
remplissage, qui s'inverse à l'appui. Grille de vignettes espacée de 2 pt, façon
planche contact.

Pour ajuster l'ensemble, il suffit de modifier `FT.Palette`, `FT.Typography` et
`FT.Metric` : app et widget suivent.

## Limites connues

- Accès **limité** aux photos : seule la sélection autorisée est visible. Les
  réglages de l'app proposent d'élargir cette sélection.
- Le 29 février est ignoré pour les années non bissextiles, pour ne pas
  décaler le libellé d'un jour.
- Photos sans date de prise de vue (`creationDate` nil) : ignorées.
- Les vidéos ne sont pas incluses (widget statique).
