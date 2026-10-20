# FlashTime

Application iOS affichant chaque jour les photos prises à la même date, les
années précédentes, directement sur l'écran d'accueil.

---

## Intention

Les photothèques modernes contiennent des milliers d'images que l'on ne revoit
jamais. Certaines applications proposent une rubrique « souvenirs », mais elle
suppose une démarche active : ouvrir l'application, chercher, faire défiler.

FlashTime inverse cette logique. Le souvenir n'est plus une destination, il
devient un élément d'ambiance. Une photo prise il y a dix ans ce jour-là apparaît
sur le fond d'écran, avec la mention « Il y a 10 ans », sans qu'aucune action ne
soit nécessaire. L'utilisateur redécouvre ses archives par accident, ce qui est
précisément l'effet recherché.

## Support et technologies

| | |
|---|---|
| **Plateforme** | iOS et iPadOS |
| **Langage** | Swift |
| **Interface** | SwiftUI |
| **Widget** | WidgetKit — quatre tailles, du petit format au très grand sur iPad |
| **Accès aux photos** | PhotoKit |
| **Partage app / widget** | App Group |
| **Environnement** | Xcode, versionnage Git sur GitHub |

L'application se compose de deux cibles distinctes : l'application elle-même et
une extension widget, qui partagent une couche de code commune.

## Fonctionnement

L'utilisateur autorise l'accès à sa photothèque au premier lancement. Une requête
recherche ensuite les photos dont la date de prise de vue correspond au jour et
au mois du jour courant, sur une fenêtre paramétrable pouvant remonter jusqu'à
cinquante ans.

L'application présente ces souvenirs regroupés par ancienneté et permet de les
consulter en plein écran. Le widget, lui, fait tourner la sélection au fil de la
journée.

L'interface est disponible en anglais, français, italien et allemand. La
langue se choisit au premier lancement, puis un court tutoriel présente le
principe de l'application, avant que des bulles d'aide ne guident
l'utilisateur pas à pas sur l'écran principal. Le changement de langue
s'applique immédiatement, widget compris, sans redémarrage.

Aucune donnée ne quitte l'appareil. Il n'y a ni serveur, ni compte utilisateur,
ni transfert réseau : l'application lit la photothèque locale et rien d'autre.

## Problèmes techniques résolus

Trois difficultés ont structuré le développement.

**Contrainte mémoire des extensions.** Une extension widget dispose d'environ
trente mégaoctets, très en deçà d'une application classique. Charger plusieurs
photos en pleine résolution provoque une interruption immédiate du système. La
solution retenue consiste à ne lire que des métadonnées lors de la recherche,
puis à décoder les images une par une, redimensionnées à la taille exacte
d'affichage du widget plutôt qu'à leur taille d'origine.

**Persistance de l'affichage.** Un widget ne s'exécute pas en continu : le
système lui demande à l'avance une série d'états datés, puis le réveille quand il
le juge opportun. Or ce réveil n'est jamais garanti, et pratiquement inexistant
la nuit, ce qui figeait l'affichage sur la veille jusqu'à la prochaine ouverture
de l'application.

La solution ne repose plus sur ce réveil. Chaque série d'états se termine par une
entrée datée de minuit contenant déjà la photo du lendemain, image comprise. Le
changement de date est donc anticipé plutôt que subi. Aucun état ne franchit
minuit, faute de quoi la mention « il y a X ans » deviendrait fausse.

**Curation par l'utilisateur.** Toutes les photos d'une date ne méritent pas
d'être affichées. Un appui long permet d'en écarter une, ou d'entrer en mode
sélection multiple pour en traiter plusieurs. Les photos écartées restent
visibles dans l'application, assourdies, afin de pouvoir revenir sur ce choix.
Cette liste est stockée dans l'espace partagé entre l'application et son
extension, que le widget consulte à chaque construction.

## Direction artistique

Le parti pris est monochrome : gris anthracite, blanc légèrement chaud, aucune
couleur d'accent hors des éléments interactifs. La photographie reste ainsi la
seule source de couleur de l'interface.

La typographie assume un registre éditorial, avec des titres en petites
capitales serif fortement espacées, tandis que les textes courants restent en
sans-serif pour la lisibilité. Les formes sont anguleuses : boutons encadrés d'un
filet fin sans remplissage, grille de vignettes quasi jointives évoquant une
planche contact.

L'ensemble du système visuel — palette, échelles typographiques, composants — est
centralisé, ce qui permet de modifier l'identité de l'application et du widget
depuis un point unique.

## Compétences mobilisées

- Développement iOS natif en Swift et SwiftUI
- Conception d'une extension système et gestion de ses contraintes propres
- Partage d'état entre plusieurs cibles d'un même projet
- Intégration d'un framework système et gestion des autorisations utilisateur
- Programmation asynchrone et gestion de l'empreinte mémoire
- Conception d'un système de design cohérent et réutilisable
- Versionnage et résolution de conflits sous Git
