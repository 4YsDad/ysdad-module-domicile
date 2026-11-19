import 'modele.dart';

/// Genre de détail d’un rangement : décide des questions posées quand on le
/// « détaille » (bureau, ensemble d’armoires, unité d’armoire…).
enum GenreMeuble {
  /// Rangement ordinaire : tablettes (espaces), tiroirs, compartiments, et
  /// tringles pour une garde-robe.
  simple,

  /// Bureau : tiroirs, dessus, dessous.
  bureau,

  /// Ensemble d’armoires : unités (chacune de son type) et comptoirs.
  armoires,

  /// Une unité d’un ensemble d’armoires (voir [TypeUnite]).
  unite,
}

/// Type d’une unité d’armoire, avec ses valeurs de départ.
enum TypeUnite {
  gardeManger('Garde-manger', tablettes: 2),
  armoireBas('Armoire du bas', tablettes: 1),
  armoireCoinBas('Armoire de coin du bas', tablettes: 1),
  armoireHaut('Armoire du haut', tablettes: 2),
  lavabo('Lavabo'),
  uniteTiroirs('Unité de tiroirs', tiroirs: 3),
  rackEpices('Rack à épices', tablettes: 3);

  const TypeUnite(this.libelle, {this.tablettes = 0, this.tiroirs = 0});

  final String libelle;
  final int tablettes;
  final int tiroirs;
}

/// Noms des espaces de rangement, du bas vers le haut, comme au marché :
/// 1 → aucun nom de position ; 2 → Bas, Haut ; 3 → Bas, Centre, Haut ;
/// 4 → Bas, Centre-bas, Centre-haut, Haut ; 5 → Bas, Centre-bas, Centre,
/// Centre-haut, Haut ; plus de 5 → Bas, Centre 1… Centre n, Haut.
List<String> nomsEspaces(int nombre) {
  if (nombre <= 1) return const [];
  return switch (nombre) {
    2 => const ['Bas', 'Haut'],
    3 => const ['Bas', 'Centre', 'Haut'],
    4 => const ['Bas', 'Centre-bas', 'Centre-haut', 'Haut'],
    5 => const ['Bas', 'Centre-bas', 'Centre', 'Centre-haut', 'Haut'],
    _ => ['Bas', for (var i = 1; i <= nombre - 2; i++) 'Centre $i', 'Haut'],
  };
}

String _sansAccents(String texte) {
  const de = 'àâäéèêëîïôöùûüç';
  const vers = 'aaaeeeeiioouuuc';
  final buffer = StringBuffer();
  for (final c in texte.toLowerCase().split('')) {
    final i = de.indexOf(c);
    buffer.write(i < 0 ? c : vers[i]);
  }
  return buffer.toString();
}

/// Genre déduit du nom d’un rangement (« Bureau (meuble) » → bureau,
/// « Armoires de la vanité » → armoires…).
GenreMeuble genreDuNom(String nom) {
  final n = _sansAccents(nom.trim());
  if (n.startsWith('bureau') || n.startsWith('pupitre')) return GenreMeuble.bureau;
  if (n.startsWith('armoire')) return GenreMeuble.armoires;
  return GenreMeuble.simple;
}

/// Vrai pour les rangements où l’on accroche des cintres (garde-robe,
/// penderie, placard…) : on leur propose des tringles.
bool accepteTringles(String nom) {
  final n = _sansAccents(nom.trim());
  return n.startsWith('garde-robe') ||
      n.startsWith('garde robe') ||
      n.startsWith('penderie') ||
      n.startsWith('placard') ||
      n.startsWith('vestiaire') ||
      n.startsWith('walk-in') ||
      n.startsWith('dressing');
}

/// Vrai si ce genre ouvre sa page « Détailler » dès qu’on l’ajoute.
bool genreADetails(GenreMeuble genre) => genre != GenreMeuble.simple;

/// Un rangement concret (« Armoires », « Tiroir 2 », « Bas »…) avec ses
/// détails. Chaque niveau se détaille séparément, un à la fois, et chaque nom
/// peut être changé.
class Meuble {
  Meuble(this.nom, {GenreMeuble? genre, TypeUnite? type, String? base})
    : base = base ?? nom,
      genre = genre ?? (type != null ? GenreMeuble.unite : genreDuNom(nom)),
      typeUnite = type ?? TypeUnite.armoireBas {
    if (this.genre == GenreMeuble.unite) _valeursDuType();
  }

  String nom;

  /// Nom d’origine (« Garde-robe » pour « Garde-robe 2 ») : sert à savoir
  /// quelles questions poser, même après un changement de nom.
  final String base;

  /// Vrai dès que la personne a changé le nom (on ne le renumérote plus).
  bool renomme = false;

  final GenreMeuble genre;

  /// Pour une unité d’armoire seulement.
  TypeUnite typeUnite;

  /// Vrai dès qu’on a ouvert la page « Détailler » de ce rangement.
  bool detaille = false;

  /// Nombre de tablettes ; elles créent [espaces] (tablettes + 1 espaces).
  int tablettes = 0;

  /// Espaces de rangement entre les tablettes, du bas vers le haut.
  final List<Meuble> espaces = <Meuble>[];

  final List<Meuble> tiroirs = <Meuble>[];
  final List<Meuble> tringles = <Meuble>[];
  final List<Meuble> compartiments = <Meuble>[];

  /// Unités d’un ensemble d’armoires.
  final List<Meuble> unites = <Meuble>[];

  /// Comptoirs d’un ensemble d’armoires.
  final List<Meuble> comptoirs = <Meuble>[];

  /// Dessus et dessous d’un bureau (null = non).
  Meuble? dessus;
  Meuble? dessous;

  bool get aDesTringles => genre == GenreMeuble.simple && accepteTringles(base);

  void _valeursDuType() {
    ajusterTablettes(typeUnite.tablettes);
    ajusterTiroirs(typeUnite.tiroirs);
  }

  /// Change le type d’une unité ; reprend les valeurs de départ du type.
  void changerType(TypeUnite type) {
    if (type == typeUnite) return;
    typeUnite = type;
    _valeursDuType();
  }

  static Meuble _feuille(String nom) => Meuble(nom, genre: GenreMeuble.simple);

  static void _ajuster(List<Meuble> liste, int nombre, String base, {int max = 20}) {
    final voulu = nombre.clamp(0, max);
    if (voulu < liste.length) liste.removeRange(voulu, liste.length);
    while (liste.length < voulu) {
      liste.add(_feuille(base));
    }
    for (var i = 0; i < liste.length; i++) {
      if (!liste[i].renomme) liste[i].nom = '$base ${i + 1}';
    }
  }

  /// N tablettes donnent N + 1 espaces nommés du bas vers le haut ; sans
  /// tablette, le rangement est un seul espace (pas de sous-espace).
  void ajusterTablettes(int n) {
    tablettes = n.clamp(0, 20);
    final voulu = tablettes == 0 ? 0 : tablettes + 1;
    // Le haut reste en haut et le bas en bas : on ajoute ou retire les
    // espaces du milieu (un nom changé suit son espace).
    if (voulu == 0) {
      espaces.clear();
    } else if (espaces.isEmpty) {
      espaces.addAll([for (var i = 0; i < voulu; i++) _feuille('Espace')]);
    } else {
      while (espaces.length > voulu) {
        espaces.removeAt(espaces.length - 2);
      }
      while (espaces.length < voulu) {
        espaces.insert(espaces.length - 1, _feuille('Espace'));
      }
    }
    final noms = nomsEspaces(voulu);
    for (var i = 0; i < espaces.length; i++) {
      if (!espaces[i].renomme) espaces[i].nom = noms[i];
    }
  }

  void ajusterTiroirs(int n) => _ajuster(tiroirs, n, 'Tiroir');
  void ajusterTringles(int n) => _ajuster(tringles, n, 'Tringle', max: 6);
  void ajusterCompartiments(int n) => _ajuster(compartiments, n, 'Compartiment');

  void ajusterComptoirs(int n) {
    _ajuster(comptoirs, n, 'Comptoir', max: 6);
    if (comptoirs.length == 1 && !comptoirs.single.renomme) comptoirs.single.nom = 'Comptoir';
  }

  void changerDessus(bool oui) => dessus = oui ? (dessus ?? _feuille('Dessus')) : null;
  void changerDessous(bool oui) => dessous = oui ? (dessous ?? _feuille('Dessous')) : null;

  /// Ajoute (ou retire) des unités ; les nouvelles sont des « Armoire du bas ».
  void ajusterUnites(int n) {
    final voulu = n.clamp(0, 30);
    if (voulu < unites.length) unites.removeRange(voulu, unites.length);
    while (unites.length < voulu) {
      unites.add(Meuble(TypeUnite.armoireBas.libelle, type: TypeUnite.armoireBas));
    }
    renumeroterUnites();
  }

  /// « Armoire du bas 1 », « Armoire du bas 2 »… par type (noms changés gardés).
  void renumeroterUnites() {
    for (final type in TypeUnite.values) {
      final memes = unites.where((u) => u.typeUnite == type).toList();
      for (var i = 0; i < memes.length; i++) {
        if (memes[i].renomme) continue;
        memes[i].nom = memes.length == 1 ? type.libelle : '${type.libelle} ${i + 1}';
      }
    }
  }

  /// Tout ce que ce rangement contient, dans l’ordre de l’arbre.
  List<Meuble> get sousRangements => [
    if (dessus != null) dessus!,
    ...comptoirs,
    ...unites,
    ...espaces,
    ...tringles,
    ...tiroirs,
    ...compartiments,
    if (dessous != null) dessous!,
  ];

  /// Sous-rangements qui se détaillent à leur tour (pas le dessus, les
  /// comptoirs ni le dessous).
  bool detaillable(Meuble enfant) => enfant != dessus && enfant != dessous && !comptoirs.contains(enfant);

  /// Nombre de sous-rangements, tous niveaux compris.
  int get totalSous => sousRangements.fold<int>(0, (somme, m) => somme + 1 + m.totalSous);

  static String _n(int n, String mot) => '$n $mot${n > 1 ? 's' : ''}';

  /// Résumé court sous le nom (« 2 tablettes (3 espaces), 1 tringle »).
  String get resume {
    final morceaux = <String>[
      if (genre == GenreMeuble.unite && nom != typeUnite.libelle) typeUnite.libelle,
      if (unites.isNotEmpty) _n(unites.length, 'unité'),
      if (comptoirs.isNotEmpty) _n(comptoirs.length, 'comptoir'),
      if (tablettes > 0) '${_n(tablettes, 'tablette')} (${espaces.length} espaces)',
      if (tringles.isNotEmpty) _n(tringles.length, 'tringle'),
      if (tiroirs.isNotEmpty) _n(tiroirs.length, 'tiroir'),
      if (compartiments.isNotEmpty) _n(compartiments.length, 'compartiment'),
      if (dessus != null) 'dessus',
      if (dessous != null) 'dessous',
    ];
    return morceaux.join(', ');
  }

  NoeudDomicile noeud() {
    final nomPropre = nom.trim().isEmpty ? (base.trim().isEmpty ? 'Rangement' : base) : nom.trim();
    return NoeudDomicile(
      type: TypeNoeud.rangement,
      nom: nomPropre,
      description:
          genre == GenreMeuble.unite && renomme && nomPropre != typeUnite.libelle ? typeUnite.libelle : null,
      enfants: [for (final m in sousRangements) m.noeud()],
    );
  }
}

/// Un rangement d’une pièce, avec son nombre : « Garde-robe × 2 » donne
/// « Garde-robe 1 » et « Garde-robe 2 ». Le nombre se change avec les flèches.
class GroupeRangement {
  GroupeRangement(this.base, {this.suggere = false, int nombre = 0}) {
    ajuster(nombre);
  }

  final String base;

  /// Vrai pour les rangements proposés d’office par le type de pièce (ils
  /// restent affichés à 0 ; les autres disparaissent à 0).
  final bool suggere;

  final List<Meuble> instances = <Meuble>[];

  int get nombre => instances.length;

  GenreMeuble get genre => genreDuNom(base);

  void ajuster(int voulu) {
    final n = voulu.clamp(0, 20);
    if (n < instances.length) instances.removeRange(n, instances.length);
    while (instances.length < n) {
      instances.add(Meuble(base));
    }
    // « Tiroirs × 3 » donne Tiroir 1, Tiroir 2, Tiroir 3 (un mot au pluriel).
    final unMot = !base.contains(' ') && base.length > 3 && base.endsWith('s');
    final singulier = unMot ? base.substring(0, base.length - 1) : base;
    for (var i = 0; i < instances.length; i++) {
      if (instances[i].renomme) continue;
      instances[i].nom = instances.length == 1 ? base : '$singulier ${i + 1}';
    }
  }
}
