import 'package:flutter/widgets.dart';

import 'modele.dart';

/// Une façon de produire l’arbre d’un domicile.
///
/// Aujourd’hui : [SourceQuestions] (l’assistant à boutons). Demain, par
/// exemple, une source « visite vidéo » analysée par l’IA pourra implémenter
/// la même interface : elle produira un [NoeudDomicile] que l’application
/// traitera exactement comme celui de l’assistant (et qu’on pourra relire
/// avec `ouvrirAssistantDomicile(…, arbreInitial: …)` avant de confirmer).
abstract interface class SourceDomicile {
  /// Identifiant court et stable, p. ex. « questions » ou « video ».
  String get id;

  /// Libellé français montré à la personne.
  String get libelle;

  /// Produit l’arbre, ou `null` si la personne abandonne.
  Future<ResultatDomicile?> produire(BuildContext context);
}
