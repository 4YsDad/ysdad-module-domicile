# ysdad_domicile — Module Ysdad « Domicile »

Assistant guidé, en français et en plein écran, qui décrit un domicile
(extérieur, étages, pièces, rangements) et rend un **arbre neutre**. Chaque
application (Trouve-tout, déménagement, rénovation…) transforme cet arbre dans
son propre modèle de données. Le module ne touche à aucune base de données.

## Ce que fait l’assistant

1. **Type de lieu** : Domicile (intérieur + extérieur), Chalet, Bureau,
   Entrepôt ou Autre. Nom facultatif, prérempli (« Maison » pour un domicile).
   Bouton **« Sans aide : créer seulement ce lieu »** (nom seulement).
2. **Extérieur** : cour avant, cour arrière, cours sur les côtés (aucune, un
   côté, les deux) ; dans la cour : galerie, remises (compteur), coffres de
   rangement (compteur), spa, piscine, et « Autre » en texte libre.
3. **Maison** : nombre d’étages, étages habitables, sous-sol, grenier, cave.
4. **Pièces de chaque étage** : compteurs (cuisine, salon, salle à manger,
   salle de bain, chambre, bureau, buanderie, couloir, escalier, entrée,
   rangement, autre). Chaque pièce peut être renommée ; ses rangements sont
   proposés en puces (p. ex. Cuisine : armoires, tiroirs, tiroir sous la
   cuisinière ; Chambre et Entrée : garde-robe ; Salle de bain : armoires de
   la vanité). Le bouton **« + Contenant »** de chaque pièce ouvre une liste
   (tablette, tiroir, bureau, mur, boîte, bac, sac, armoire, étagère, table,
   meuble, pupitre, banc, frigo, congélo, alcôve, coffre, classeur, commode,
   placard, penderie, panier, valise, comptoir…) : un toucher l’ajoute, ou on
   tape un autre nom au clavier.
   Chaque rangement a ses **flèches ▼ ▲** pour en retirer ou en ajouter un
   directement (« Garde-robe × 2 » donne Garde-robe 1 et Garde-robe 2).
   Toucher un rangement ouvre sa page **« Détailler »**, un niveau à la fois :
   - **Bureau** (ou pupitre) : nombre de tiroirs (Tiroir 1, Tiroir 2…),
     dessus, dessous ; chaque tiroir se détaille à son tour.
   - **Armoires** : nombre d’unités, nombre de comptoirs ; chaque unité a un
     nom et un type (garde-manger en 1 à 5 sections bas, centre-bas, centre,
     centre-haut, haut ; armoire du bas ; armoire de coin du bas ; armoire du
     haut ; lavabo ; unité de tiroirs ; rack à épices) et ses tablettes et
     tiroirs.
   - Tout autre rangement : compartiments, tablettes, tiroirs.
   Bureau et armoires ouvrent leur page dès qu’on les ajoute ou qu’on les touche.
   Tout se retrouve dans l’arbre (`rangement` avec ses `enfants`).
5. **Garage** : attaché ou détaché, mezzanines (compteur), murs utilisés comme
   zones, établi, armoires, étagères.
6. **Résumé** en arbre, puis « Créer N lieux ».

Chaque étape peut être **passée** ; le bouton Retour (ou le retour Android)
recule d’une étape. Gros boutons, fonctionne sur téléphone et sur pliable
déplié. Aucune boîte de dialogue : les erreurs restent affichées sous le champ.

## Installation

```yaml
dependencies:
  ysdad_domicile:
    git:
      url: https://github.com/4YsDad/ysdad-module-domicile.git
      ref: main
```

## Utilisation

```dart
import 'package:ysdad_domicile/ysdad_domicile.dart';

final resultat = await ouvrirAssistantDomicile(
  context,
  options: const OptionsAssistantDomicile(
    nomPropose: 'Maison',
    noteFinale: 'Vous pourrez ajouter des photos à chaque lieu plus tard.',
  ),
);
if (resultat != null) {
  for (final (:noeud, :profondeur) in resultat.arbre.parcourir()) {
    // noeud.type (lieu, exterieur, etage, piece, rangement), noeud.nom,
    // noeud.description, noeud.photos, noeud.enfants
  }
}
```

La même liste est offerte seule à l’appli hôte (p. ex. pour ajouter un
sous-lieu) :

```dart
final nom = await choisirContenant(context); // null si on ferme
```

## Modèle

- `NoeudDomicile` : `type` (`TypeNoeud.lieu`, `exterieur`, `etage`, `piece`,
  `rangement`), `nom`, `description` facultative, `enfants`, `photos`
  (chemins locaux, facultatifs). `toJson()` / `fromJson()` fournis.
- `ResultatDomicile` : `arbre`, `sansAide`, `source`.
- `ReponsesDomicile` : les réponses de l’assistant ; `arbre()` construit
  l’arbre (utile pour les tests ou pour préremplir).

## Sources (extensible)

`SourceDomicile` est l’interface commune à toute façon de produire l’arbre :

```dart
abstract interface class SourceDomicile {
  String get id;        // « questions », plus tard « video »…
  String get libelle;
  Future<ResultatDomicile?> produire(BuildContext context);
}
```

- `SourceQuestions` : l’assistant à boutons (disponible).
- Une future source « visite vidéo » analysée par l’IA pourra implémenter la
  même interface, rendre un `NoeudDomicile`, et le faire confirmer avec
  `confirmerArbreDomicile(context, arbre, source: 'video')`. Rien n’est
  implémenté pour la vidéo dans cette version.

## Tests

```
flutter test
```
