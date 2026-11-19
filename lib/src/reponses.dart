import 'meubles.dart';
import 'modele.dart';

/// Type de pièce proposé dans l’assistant, avec ses rangements suggérés.
/// Ceux de [coches] sont cochés d’office (on peut les décocher).
class TypePiece {
  const TypePiece(this.id, this.nom, this.sousLieux, {this.coches = const []});

  final String id;
  final String nom;
  final List<String> sousLieux;
  final List<String> coches;
}

const kTypesPieces = <TypePiece>[
  TypePiece(
    'cuisine',
    'Cuisine',
    ['Armoires', 'Tiroirs', 'Tiroir sous la cuisinière', 'Garde-manger', 'Réfrigérateur'],
    coches: ['Armoires', 'Tiroirs', 'Tiroir sous la cuisinière'],
  ),
  TypePiece('salon', 'Salon', ['Meuble télé', 'Bibliothèque']),
  TypePiece('salle-a-manger', 'Salle à manger', ['Buffet', 'Vaisselier']),
  TypePiece(
    'salle-de-bain',
    'Salle de bain',
    ['Armoires de la vanité', 'Pharmacie'],
    coches: ['Armoires de la vanité'],
  ),
  TypePiece('chambre', 'Chambre', ['Garde-robe', 'Commode', 'Table de chevet'], coches: ['Garde-robe']),
  TypePiece('bureau', 'Bureau', ['Bureau (meuble)', 'Classeur', 'Étagères']),
  TypePiece('buanderie', 'Buanderie', ['Armoires', 'Tablettes']),
  TypePiece('couloir', 'Couloir', ['Placard']),
  TypePiece('escalier', 'Escalier', ['Tablette']),
  TypePiece('entree', 'Entrée', ['Garde-robe', 'Banc à chaussures'], coches: ['Garde-robe']),
  TypePiece('rangement', 'Rangement', ['Étagères']),
  TypePiece('autre', 'Autre pièce', []),
];

TypePiece typePiece(String id) => kTypesPieces.firstWhere((type) => type.id == id);

/// Contenants offerts par le bouton « + Contenant » (un toucher = ajouté).
const kContenants = <String>[
  'Tablette',
  'Tiroir',
  'Bureau',
  'Mur',
  'Boîte',
  'Bac',
  'Sac',
  'Armoire',
  'Étagère',
  'Table',
  'Meuble',
  'Pupitre',
  'Banc',
  'Frigo',
  'Congélo',
  'Alcôve',
  'Comptoir',
  'Coffre',
  'Classeur',
  'Commode',
  'Placard',
  'Penderie',
  'Panier',
  'Valise',
  'Coffre-fort',
  'Bibliothèque',
];

/// Donne un nom unique dans [existants] : « Tiroir », puis « Tiroir 2 »…
String nomUnique(String nom, Iterable<String> existants) {
  final pris = existants.map((e) => e.toLowerCase()).toSet();
  if (!pris.contains(nom.toLowerCase())) return nom;
  var i = 2;
  while (pris.contains('$nom $i'.toLowerCase())) {
    i++;
  }
  return '$nom $i';
}

class Piece {
  Piece(this.type, this.nom) {
    for (final sous in type.sousLieux) {
      groupes.add(GroupeRangement(sous, suggere: true, nombre: type.coches.contains(sous) ? 1 : 0));
    }
  }

  final TypePiece type;
  String nom;

  /// Vrai dès que la personne a changé le nom (on ne le renumérote plus).
  bool renomme = false;

  /// Rangements de la pièce : d’abord ceux suggérés par le type (même à 0),
  /// puis ceux ajoutés avec « + Contenant », dans l’ordre.
  final List<GroupeRangement> groupes = <GroupeRangement>[];

  GroupeRangement? groupe(String base) {
    for (final g in groupes) {
      if (g.base.toLowerCase() == base.trim().toLowerCase()) return g;
    }
    return null;
  }

  /// Ajoute un rangement : s’il existe déjà, son nombre augmente de 1.
  /// Renvoie le rangement créé (ou `null` si le nom est vide).
  Meuble? ajouterContenant(String nom) {
    final propre = nom.trim();
    if (propre.isEmpty) return null;
    var g = groupe(propre);
    if (g == null) {
      g = GroupeRangement(propre);
      groupes.add(g);
    }
    g.ajuster(g.nombre + 1);
    return g.instances.last;
  }

  /// Change le nombre d’un rangement (flèches). À 0, un rangement ajouté à la
  /// main disparaît ; un rangement suggéré reste proposé.
  void ajuster(GroupeRangement g, int nombre) {
    g.ajuster(nombre);
    if (g.nombre == 0 && !g.suggere) groupes.remove(g);
  }

  /// Tous les rangements de la pièce (premier niveau), dans l’ordre.
  List<Meuble> get meubles => [for (final g in groupes) ...g.instances];

  /// Noms des rangements du premier niveau.
  List<String> get rangements => [for (final m in meubles) m.nom];
}

class Niveau {
  Niveau(this.cle, this.nom, {this.habitable = true});

  final String cle;
  String nom;
  bool habitable;
  final List<Piece> pieces = <Piece>[];

  /// Vrai quand la personne a déjà vu (ou modifié) les pièces de ce niveau.
  bool initialise = false;

  int nombre(TypePiece type) => pieces.where((piece) => piece.type.id == type.id).length;

  void ajuster(TypePiece type, int nombreVoulu) {
    final actuelles = pieces.where((piece) => piece.type.id == type.id).toList();
    if (nombreVoulu < actuelles.length) {
      for (final piece in actuelles.sublist(nombreVoulu)) {
        pieces.remove(piece);
      }
    } else {
      for (var i = actuelles.length; i < nombreVoulu; i++) {
        pieces.add(Piece(type, type.nom));
      }
    }
    _renumeroter(type);
  }

  void _renumeroter(TypePiece type) {
    final memes = pieces.where((piece) => piece.type.id == type.id).toList();
    for (var i = 0; i < memes.length; i++) {
      if (memes[i].renomme) continue;
      memes[i].nom = memes.length == 1 ? type.nom : '${type.nom} ${i + 1}';
    }
  }
}

enum TypeDomicile {
  domicile('Domicile', 'Intérieur et extérieur', 'Maison'),
  chalet('Chalet', 'Intérieur et extérieur', 'Chalet'),
  bureau('Bureau', 'Pièces et zones', 'Bureau'),
  entrepot('Entrepôt', 'Pièces et zones', 'Entrepôt'),
  autre('Autre', 'Un nom libre', '');

  const TypeDomicile(this.libelle, this.detail, this.nomParDefaut);

  final String libelle;
  final String detail;
  final String nomParDefaut;

  /// Domicile et chalet : extérieur, intérieur et garage.
  bool get complet => this == TypeDomicile.domicile || this == TypeDomicile.chalet;
}

String nomEtage(int numero) => switch (numero) {
  1 => 'Rez-de-chaussée',
  2 => '2e étage',
  _ => '${numero}e étage',
};

/// Réponses de l’assistant ; [arbre] produit l’arbre du domicile.
class ReponsesDomicile {
  ReponsesDomicile({this.type = TypeDomicile.domicile, String? nom}) : nom = nom ?? type.nomParDefaut;

  TypeDomicile type;
  String nom;

  // Extérieur
  bool exterieur = true;
  bool courAvant = true;
  bool courArriere = true;

  /// 0 = aucune, 1 = un côté, 2 = les deux côtés.
  int coursCote = 0;
  bool galerie = false;
  int remises = 0;
  int coffres = 0;
  bool spa = false;
  bool piscine = false;
  final List<String> autresExterieur = <String>[];

  // Maison
  int etages = 1;
  int habitables = 1;
  bool grenier = false;
  bool cave = false;
  bool sousSol = false;

  // Garage
  bool garage = false;
  bool garageAttache = true;
  int mezzanines = 0;
  int murs = 0;
  bool etabli = false;
  bool armoires = false;
  bool etageres = false;

  final Map<String, Niveau> _niveaux = <String, Niveau>{};

  void changerType(TypeDomicile nouveau) {
    type = nouveau;
    if (!nouveau.complet) {
      exterieur = false;
      garage = false;
    } else {
      exterieur = true;
    }
  }

  void changerEtages(int valeur) {
    final suivait = habitables == etages;
    etages = valeur.clamp(1, 9);
    if (suivait || habitables > etages) habitables = etages;
  }

  void changerHabitables(int valeur) => habitables = valeur.clamp(0, etages);

  /// Niveaux de la maison, du bas vers le haut. Les réponses déjà données sont
  /// gardées si on revient en arrière et qu’on change le nombre d’étages.
  List<Niveau> get niveaux {
    final liste = <Niveau>[];
    if (sousSol) {
      liste.add(_niveaux.putIfAbsent('sous-sol', () => Niveau('sous-sol', 'Sous-sol')));
    }
    for (var i = 1; i <= etages; i++) {
      final niveau = _niveaux.putIfAbsent('etage-$i', () => Niveau('etage-$i', nomEtage(i)));
      niveau.habitable = i <= habitables;
      liste.add(niveau);
    }
    return liste;
  }

  /// Pièces proposées la première fois qu’on ouvre un niveau (tout se retire).
  void preremplir(Niveau niveau) {
    if (niveau.initialise) return;
    niveau.initialise = true;
    if (!type.complet || !niveau.habitable || niveau.cle == 'sous-sol') return;
    final unSeul = etages == 1;
    if (niveau.cle == 'etage-1') {
      for (final id in ['entree', 'cuisine', 'salon', 'salle-a-manger']) {
        niveau.ajuster(typePiece(id), 1);
      }
      if (unSeul) {
        niveau.ajuster(typePiece('salle-de-bain'), 1);
        niveau.ajuster(typePiece('chambre'), 2);
      } else {
        niveau.ajuster(typePiece('escalier'), 1);
      }
    } else {
      niveau.ajuster(typePiece('salle-de-bain'), 1);
      niveau.ajuster(typePiece('chambre'), 2);
    }
  }

  NoeudDomicile arbre() {
    final racine = NoeudDomicile(type: TypeNoeud.lieu, nom: nom.trim().isEmpty ? type.libelle : nom.trim());
    final interieur = _interieur();
    if (type.complet) {
      final ext = _exterieur();
      final gar = _garage();
      if (ext != null) racine.enfants.add(ext);
      // « Intérieur » vide et seul n’apporte rien : on ne le crée pas.
      if (interieur.isNotEmpty || ext != null || gar != null) {
        racine.enfants.add(NoeudDomicile(type: TypeNoeud.lieu, nom: 'Intérieur', enfants: interieur));
      }
      if (gar != null) racine.enfants.add(gar);
    } else {
      racine.enfants.addAll(interieur);
    }
    return racine;
  }

  static NoeudDomicile _ext(String nom, [List<NoeudDomicile>? enfants]) =>
      NoeudDomicile(type: TypeNoeud.exterieur, nom: nom, enfants: enfants);

  static NoeudDomicile _rang(String nom) => NoeudDomicile(type: TypeNoeud.rangement, nom: nom);

  NoeudDomicile? _exterieur() {
    if (!exterieur) return null;
    final ext = _ext('Extérieur');
    if (courAvant) ext.enfants.add(_ext('Cour avant'));
    final arriere = <NoeudDomicile>[
      if (galerie) _ext('Galerie'),
      ..._numerotes(remises, 'Remise', TypeNoeud.exterieur),
      ..._numerotes(coffres, 'Coffre de rangement', TypeNoeud.rangement),
      if (spa) _ext('Spa'),
      if (piscine) _ext('Piscine'),
    ];
    if (courArriere) {
      ext.enfants.add(_ext('Cour arrière', arriere));
    } else {
      ext.enfants.addAll(arriere);
    }
    if (coursCote == 1) ext.enfants.add(_ext('Cour latérale'));
    if (coursCote == 2) {
      ext.enfants
        ..add(_ext('Cour côté gauche'))
        ..add(_ext('Cour côté droit'));
    }
    for (final autre in autresExterieur) {
      if (autre.trim().isNotEmpty) ext.enfants.add(_ext(autre.trim()));
    }
    return ext;
  }

  List<NoeudDomicile> _interieur() {
    final liste = niveaux;
    final noeuds = <NoeudDomicile>[];
    List<NoeudDomicile> pieces(Niveau niveau) => [
      for (final piece in niveau.pieces)
        NoeudDomicile(
          type: TypeNoeud.piece,
          nom: piece.nom.trim().isEmpty ? piece.type.nom : piece.nom.trim(),
          enfants: [for (final meuble in piece.meubles) meuble.noeud()],
        ),
    ];
    if (liste.length == 1) {
      noeuds.addAll(pieces(liste.single));
    } else {
      for (final niveau in liste) {
        noeuds.add(
          NoeudDomicile(
            type: TypeNoeud.etage,
            nom: niveau.nom,
            description: niveau.habitable ? null : 'Étage non habitable',
            enfants: pieces(niveau),
          ),
        );
      }
    }
    if (grenier) noeuds.add(NoeudDomicile(type: TypeNoeud.etage, nom: 'Grenier'));
    if (cave) noeuds.add(NoeudDomicile(type: TypeNoeud.etage, nom: 'Cave'));
    return noeuds;
  }

  NoeudDomicile? _garage() {
    if (!garage) return null;
    return NoeudDomicile(
      type: TypeNoeud.lieu,
      nom: 'Garage',
      description: garageAttache ? 'Attaché à la maison' : 'Détaché de la maison',
      enfants: [
        ..._numerotes(mezzanines, 'Mezzanine', TypeNoeud.rangement),
        for (var i = 1; i <= murs; i++) _rang('Mur $i'),
        if (etabli) _rang('Établi'),
        if (armoires) _rang('Armoires'),
        if (etageres) _rang('Étagères'),
      ],
    );
  }

  static List<NoeudDomicile> _numerotes(int nombre, String nom, TypeNoeud type) => [
    for (var i = 1; i <= nombre; i++) NoeudDomicile(type: type, nom: nombre == 1 ? nom : '$nom $i'),
  ];
}
