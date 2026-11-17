/// Type d’un nœud de l’arbre du domicile.
enum TypeNoeud {
  /// Le lieu du haut (domicile, chalet, bureau…) ou un bloc comme
  /// « Intérieur » ou « Garage ».
  lieu,

  /// Une zone extérieure : cour, galerie, remise, spa, piscine…
  exterieur,

  /// Un niveau : sous-sol, rez-de-chaussée, 2e étage, grenier, cave.
  etage,

  /// Une pièce : cuisine, chambre, salle de bain…
  piece,

  /// Un rangement : garde-robe, armoires, tiroir, mezzanine, mur, établi…
  rangement,
}

/// Nœud neutre de l’arbre d’un domicile, indépendant de toute base de
/// données. Chaque application le transforme dans son propre modèle.
class NoeudDomicile {
  NoeudDomicile({
    required this.type,
    required this.nom,
    this.description,
    List<NoeudDomicile>? enfants,
    List<String>? photos,
  })  : enfants = enfants ?? <NoeudDomicile>[],
        photos = photos ?? <String>[];

  final TypeNoeud type;
  final String nom;
  final String? description;
  final List<NoeudDomicile> enfants;

  /// Chemins de photos locales (facultatif ; une source vidéo pourrait en
  /// fournir, l’assistant à questions n’en fournit pas).
  final List<String> photos;

  /// Nombre total de nœuds (celui-ci compris).
  int get total => 1 + enfants.fold<int>(0, (somme, enfant) => somme + enfant.total);

  /// Parcourt l’arbre en profondeur (parent avant enfants).
  Iterable<({NoeudDomicile noeud, int profondeur})> parcourir([int profondeur = 0]) sync* {
    yield (noeud: this, profondeur: profondeur);
    for (final enfant in enfants) {
      yield* enfant.parcourir(profondeur + 1);
    }
  }

  Map<String, Object?> toJson() => {
        'type': type.name,
        'nom': nom,
        if (description != null) 'description': description,
        if (photos.isNotEmpty) 'photos': photos,
        if (enfants.isNotEmpty) 'enfants': [for (final enfant in enfants) enfant.toJson()],
      };

  factory NoeudDomicile.fromJson(Map<String, Object?> json) => NoeudDomicile(
        type: TypeNoeud.values.firstWhere(
          (type) => type.name == json['type'],
          orElse: () => TypeNoeud.lieu,
        ),
        nom: (json['nom'] as String?) ?? '',
        description: json['description'] as String?,
        photos: [for (final photo in (json['photos'] as List?) ?? const []) '$photo'],
        enfants: [
          for (final enfant in (json['enfants'] as List?) ?? const [])
            NoeudDomicile.fromJson((enfant as Map).cast<String, Object?>()),
        ],
      );
}

/// Résultat rendu à l’application.
class ResultatDomicile {
  const ResultatDomicile({required this.arbre, this.sansAide = false, this.source = 'questions'});

  /// Arbre à créer. Avec [sansAide], c’est un seul nœud (le nom tapé).
  final NoeudDomicile arbre;

  /// Vrai si la personne a choisi « Sans aide : créer seulement ce lieu ».
  final bool sansAide;

  /// Identifiant de la source qui a produit l’arbre (« questions », plus tard
  /// « video »…).
  final String source;
}
