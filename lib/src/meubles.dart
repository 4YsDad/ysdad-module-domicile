import 'modele.dart';

/// Genre de détail d’un rangement : décide des questions posées quand on le
/// « détaille » (bureau, ensemble d’armoires, unité d’armoire…).
enum GenreMeuble {
  /// Rangement ordinaire : compartiments, tablettes et tiroirs.
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
  gardeManger('Garde-manger'),
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

/// Noms des sections d’un garde-manger selon leur nombre (1 à 5).
List<String> nomsSections(int nombre) => switch (nombre.clamp(1, 5)) {
  1 => const ['Centre'],
  2 => const ['Bas', 'Haut'],
  3 => const ['Bas', 'Centre', 'Haut'],
  4 => const ['Bas', 'Centre-bas', 'Centre-haut', 'Haut'],
  _ => const ['Bas', 'Centre-bas', 'Centre', 'Centre-haut', 'Haut'],
};

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

/// Vrai si ce genre ouvre sa page « Détailler » dès qu’on l’ajoute.
bool genreADetails(GenreMeuble genre) => genre != GenreMeuble.simple;

/// Un rangement concret (« Armoires », « Tiroir 2 », « Garde-manger »…) avec
/// ses détails. Chaque niveau se détaille séparément, un à la fois.
class Meuble {
  Meuble(this.nom, {GenreMeuble? genre, TypeUnite? type})
    : genre = genre ?? (type != null ? GenreMeuble.unite : genreDuNom(nom)),
      typeUnite = type ?? TypeUnite.armoireBas {
    if (this.genre == GenreMeuble.unite) _valeursDuType();
  }

  String nom;

  /// Vrai dès que la personne a changé le nom (on ne le renumérote plus).
  bool renomme = false;

  final GenreMeuble genre;

  /// Pour une unité d’armoire seulement.
  TypeUnite typeUnite;

  /// Vrai dès qu’on a ouvert la page « Détailler » de ce rangement.
  bool detaille = false;

  final List<Meuble> tablettes = <Meuble>[];
  final List<Meuble> tiroirs = <Meuble>[];
  final List<Meuble> compartiments = <Meuble>[];

  /// Sections d’un garde-manger (bas, centre, haut…).
  final List<Meuble> sections = <Meuble>[];

  /// Unités d’un ensemble d’armoires.
  final List<Meuble> unites = <Meuble>[];

  int comptoirs = 0;
  bool dessus = false;
  bool dessous = false;

  bool get estGardeManger => genre == GenreMeuble.unite && typeUnite == TypeUnite.gardeManger;

  void _valeursDuType() {
    ajusterTablettes(typeUnite.tablettes);
    ajusterTiroirs(typeUnite.tiroirs);
    ajusterSections(typeUnite == TypeUnite.gardeManger ? 3 : 0);
  }

  /// Change le type d’une unité ; reprend les valeurs de départ du type.
  void changerType(TypeUnite type) {
    if (type == typeUnite) return;
    typeUnite = type;
    _valeursDuType();
  }

  static void _ajuster(List<Meuble> liste, int nombre, String base, {int max = 20}) {
    final voulu = nombre.clamp(0, max);
    if (voulu < liste.length) {
      liste.removeRange(voulu, liste.length);
    }
    while (liste.length < voulu) {
      liste.add(Meuble(base, genre: GenreMeuble.simple));
    }
    for (var i = 0; i < liste.length; i++) {
      if (!liste[i].renomme) liste[i].nom = '$base ${i + 1}';
    }
  }

  void ajusterTablettes(int n) => _ajuster(tablettes, n, 'Tablette');
  void ajusterTiroirs(int n) => _ajuster(tiroirs, n, 'Tiroir');
  void ajusterCompartiments(int n) => _ajuster(compartiments, n, 'Compartiment');

  void ajusterSections(int n) {
    final voulu = n.clamp(0, 5);
    if (voulu < sections.length) sections.removeRange(voulu, sections.length);
    while (sections.length < voulu) {
      sections.add(Meuble('Section', genre: GenreMeuble.simple));
    }
    final noms = voulu == 0 ? const <String>[] : nomsSections(voulu);
    for (var i = 0; i < sections.length; i++) {
      if (!sections[i].renomme) sections[i].nom = noms[i];
    }
  }

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

  /// Enfants que ce rangement produira, dans l’ordre affiché.
  List<Meuble> get sousRangements => [...sections, ...unites, ...compartiments, ...tablettes, ...tiroirs];

  /// Nombre de sous-rangements, tous niveaux compris.
  int get totalSous => sousRangements.fold<int>(
    (genre == GenreMeuble.bureau ? (dessus ? 1 : 0) + (dessous ? 1 : 0) : 0) + comptoirs,
    (somme, m) => somme + 1 + m.totalSous,
  );

  /// Résumé court sous le nom (« 3 tiroirs, dessus »).
  String get resume {
    final morceaux = <String>[
      if (genre == GenreMeuble.unite) typeUnite.libelle,
      if (unites.isNotEmpty) '${unites.length} unité${unites.length > 1 ? 's' : ''}',
      if (comptoirs > 0) '$comptoirs comptoir${comptoirs > 1 ? 's' : ''}',
      if (sections.isNotEmpty) '${sections.length} section${sections.length > 1 ? 's' : ''}',
      if (compartiments.isNotEmpty)
        '${compartiments.length} compartiment${compartiments.length > 1 ? 's' : ''}',
      if (tablettes.isNotEmpty) '${tablettes.length} tablette${tablettes.length > 1 ? 's' : ''}',
      if (tiroirs.isNotEmpty) '${tiroirs.length} tiroir${tiroirs.length > 1 ? 's' : ''}',
      if (genre == GenreMeuble.bureau && dessus) 'dessus',
      if (genre == GenreMeuble.bureau && dessous) 'dessous',
    ];
    return morceaux.join(', ');
  }

  NoeudDomicile noeud() {
    final nomPropre = nom.trim().isEmpty ? 'Rangement' : nom.trim();
    final enfants = <NoeudDomicile>[
      if (genre == GenreMeuble.bureau && dessus) NoeudDomicile(type: TypeNoeud.rangement, nom: 'Dessus'),
      if (comptoirs == 1) NoeudDomicile(type: TypeNoeud.rangement, nom: 'Comptoir'),
      if (comptoirs > 1)
        for (var i = 1; i <= comptoirs; i++) NoeudDomicile(type: TypeNoeud.rangement, nom: 'Comptoir $i'),
      for (final m in sousRangements) m.noeud(),
      if (genre == GenreMeuble.bureau && dessous) NoeudDomicile(type: TypeNoeud.rangement, nom: 'Dessous'),
    ];
    return NoeudDomicile(
      type: TypeNoeud.rangement,
      nom: nomPropre,
      description: genre == GenreMeuble.unite && nomPropre != typeUnite.libelle ? typeUnite.libelle : null,
      enfants: enfants,
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
    for (var i = 0; i < instances.length; i++) {
      if (instances[i].renomme) continue;
      instances[i].nom = instances.length == 1 ? base : '$base ${i + 1}';
    }
  }
}
