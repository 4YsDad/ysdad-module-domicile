## 1.2.0

- Flèches ▼ ▲ sur chaque rangement d’une pièce : en ajouter ou en retirer un
  sans changer d’écran (`GroupeRangement`, `Piece.groupes`, `Piece.ajuster`).
- Pages « Détailler » imbriquées (`Meuble`, `GenreMeuble`, `TypeUnite`) :
  bureau (tiroirs, dessus, dessous), armoires (unités typées, comptoirs),
  garde-manger (1 à 5 sections), tablettes et tiroirs de chaque unité,
  compartiments d’un tiroir… Le tout devient des `rangement` enfants dans
  l’arbre.
- « Crédence » retirée de `kContenants`, « Comptoir » ajouté.
- `Piece.ajouterContenant()` rend maintenant le `Meuble` créé ; ajouter un
  nom déjà présent augmente son nombre (« Tiroir 1 », « Tiroir 2 »).

## 1.1.0

- Bouton « + Contenant » dans chaque pièce : liste à un toucher (`kContenants`)
  et nom libre au clavier ; `choisirContenant()` est exporté pour l’appli hôte.
- « Bol à clés » retiré des suggestions automatiques (trop propre à une famille).

## 1.0.0

- Première version : assistant guidé (type, extérieur, maison, pièces par
  étage, garage, résumé), option « sans aide », arbre neutre `NoeudDomicile`,
  interface `SourceDomicile` pour de futures sources (vidéo).
- Boutons du bas sur une seule ligne sur téléphone ; compteurs sur deux
  colonnes sur grand écran (Fold déplié).
