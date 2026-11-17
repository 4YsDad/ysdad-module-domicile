import 'package:flutter/material.dart';

import 'modele.dart';
import 'reponses.dart';
import 'source.dart';
import 'vue.dart';

/// Options de l’assistant.
class OptionsAssistantDomicile {
  const OptionsAssistantDomicile({
    this.typeInitial = TypeDomicile.domicile,
    this.nomPropose,
    this.permettreSansAide = true,
    this.noteFinale,
  });

  /// Type choisi au départ (modifiable).
  final TypeDomicile typeInitial;

  /// Nom prérempli ; sinon le nom par défaut du type (p. ex. « Maison »).
  final String? nomPropose;

  /// Affiche le bouton « Sans aide : créer seulement ce lieu ».
  final bool permettreSansAide;

  /// Texte affiché sous le résumé (p. ex. comment ajouter des photos ensuite).
  final String? noteFinale;
}

/// Ouvre l’assistant plein écran. Rend l’arbre confirmé, ou `null` si la
/// personne quitte.
Future<ResultatDomicile?> ouvrirAssistantDomicile(
  BuildContext context, {
  OptionsAssistantDomicile options = const OptionsAssistantDomicile(),
}) {
  return Navigator.of(context).push<ResultatDomicile>(
    MaterialPageRoute<ResultatDomicile>(
      builder: (_) => AssistantDomicileScreen(options: options),
    ),
  );
}

/// Source « questions » : l’assistant à boutons.
class SourceQuestions implements SourceDomicile {
  const SourceQuestions({this.options = const OptionsAssistantDomicile()});

  final OptionsAssistantDomicile options;

  @override
  String get id => 'questions';

  @override
  String get libelle => 'Assistant rapide (questions)';

  @override
  Future<ResultatDomicile?> produire(BuildContext context) =>
      ouvrirAssistantDomicile(context, options: options);
}

/// Assistant plein écran « Ajouter un lieu » (pas une boîte de dialogue :
/// le champ, les messages d’erreur et les boutons restent toujours visibles).
class AssistantDomicileScreen extends StatefulWidget {
  const AssistantDomicileScreen({super.key, this.options = const OptionsAssistantDomicile()});

  final OptionsAssistantDomicile options;

  @override
  State<AssistantDomicileScreen> createState() => _AssistantDomicileScreenState();
}

class _AssistantDomicileScreenState extends State<AssistantDomicileScreen> {
  late final ReponsesDomicile _a;
  final _nom = TextEditingController();
  final _nomFocus = FocusNode();
  final _autreExt = TextEditingController();
  bool _nomModifie = false;
  String? _erreurNom;
  int _etape = 0;

  @override
  void initState() {
    super.initState();
    _a = ReponsesDomicile(type: widget.options.typeInitial);
    _a.changerType(widget.options.typeInitial);
    final nom = widget.options.nomPropose ?? _a.type.nomParDefaut;
    _a.nom = nom;
    _nom.text = nom;
  }

  @override
  void dispose() {
    _nom.dispose();
    _nomFocus.dispose();
    _autreExt.dispose();
    super.dispose();
  }

  // ---------- Étapes ----------

  List<String> get _etapes => [
        'type',
        if (_a.type.complet) 'exterieur',
        'maison',
        for (final niveau in _a.niveaux) 'niveau:${niveau.cle}',
        if (_a.type.complet) 'garage',
        'resume',
      ];

  String get _etapeCourante {
    final liste = _etapes;
    return liste[_etape.clamp(0, liste.length - 1)];
  }

  Niveau? _niveau(String etape) {
    if (!etape.startsWith('niveau:')) return null;
    final cle = etape.substring(7);
    for (final niveau in _a.niveaux) {
      if (niveau.cle == cle) return niveau;
    }
    return null;
  }

  void _aller(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _etape = index.clamp(0, _etapes.length - 1);
      final niveau = _niveau(_etapeCourante);
      if (niveau != null) _a.preremplir(niveau);
    });
  }

  bool _validerNom() {
    final nom = _nom.text.trim();
    if (nom.isEmpty) {
      setState(() => _erreurNom = 'Écrivez le nom du lieu, ou choisissez un type ci-dessus.');
      _nomFocus.requestFocus();
      return false;
    }
    _a.nom = nom;
    return true;
  }

  void _suivant() {
    if (_etapeCourante == 'type' && !_validerNom()) return;
    _aller(_etape + 1);
  }

  void _passer() {
    final etape = _etapeCourante;
    setState(() {
      if (etape == 'exterieur') _a.exterieur = false;
      if (etape == 'garage') _a.garage = false;
      if (etape == 'maison') {
        _a.changerEtages(1);
        _a.changerHabitables(1);
        _a.grenier = false;
        _a.cave = false;
        _a.sousSol = false;
      }
      _niveau(etape)?.pieces.clear();
    });
    _aller(_etape + 1);
  }

  void _changerType(TypeDomicile type) {
    setState(() {
      _a.changerType(type);
      _erreurNom = null;
      if (!_nomModifie) {
        _nom.text = type.nomParDefaut;
        _a.nom = type.nomParDefaut;
      }
    });
    if (type == TypeDomicile.autre && _nom.text.trim().isEmpty) _nomFocus.requestFocus();
  }

  // ---------- Création ----------

  void _terminer(NoeudDomicile arbre, {bool sansAide = false}) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(ResultatDomicile(arbre: arbre, sansAide: sansAide));
  }

  void _creerSansAide() {
    if (!_validerNom()) return;
    _terminer(NoeudDomicile(type: TypeNoeud.lieu, nom: _a.nom), sansAide: true);
  }

  // ---------- Interface ----------

  @override
  Widget build(BuildContext context) {
    final etapes = _etapes;
    final etape = _etapeCourante;
    return PopScope(
      canPop: _etape == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _aller(_etape - 1);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titre(etape)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(value: (_etape + 1) / etapes.length),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView(
                key: PageStorageKey(etape),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: _contenu(etape),
              ),
            ),
          ),
        ),
        bottomNavigationBar: _barre(etape),
      ),
    );
  }

  String _titre(String etape) {
    if (etape == 'type') return 'Ajouter un lieu';
    if (etape == 'exterieur') return 'Extérieur';
    if (etape == 'maison') return _a.type.complet ? 'La maison' : 'Les étages';
    if (etape == 'garage') return 'Garage';
    if (etape == 'resume') return 'Résumé';
    return 'Pièces · ${_niveau(etape)?.nom ?? ''}';
  }

  List<Widget> _contenu(String etape) {
    if (etape == 'type') return _etapeType();
    if (etape == 'exterieur') return _etapeExterieur();
    if (etape == 'maison') return _etapeMaison();
    if (etape == 'garage') return _etapeGarage();
    if (etape == 'resume') return _etapeResume();
    final niveau = _niveau(etape);
    return niveau == null ? const [] : _etapeNiveau(niveau);
  }

  Widget _barre(String etape) {
    final premiere = _etape == 0;
    final derniere = etape == 'resume';
    final passable = !premiere && !derniere;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            if (!premiere) ...[
              Expanded(
                child: _GrosBouton.contour(
                  key: const Key('assistant-back'),
                  label: 'Retour',
                  onPressed: () => _aller(_etape - 1),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (passable) ...[
              Expanded(
                child: _GrosBouton.texte(
                  key: const Key('assistant-skip'),
                  label: 'Passer',
                  onPressed: _passer,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              flex: 2,
              child: derniere
                  ? _GrosBouton.plein(
                      key: const Key('assistant-create'),
                      label: 'Créer ${_a.arbre().total} lieux',
                      onPressed: () => _terminer(_a.arbre()),
                    )
                  : _GrosBouton.plein(
                      key: const Key('assistant-next'),
                      label: premiere ? 'Assistant rapide' : 'Suivant',
                      onPressed: _suivant,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _etapeType() {
    final colors = _Couleurs.of(context);
    return [
      _Titre('Quel type de lieu ?'),
      const SizedBox(height: 12),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final type in TypeDomicile.values)
            _CarteChoix(
              key: Key('type-${type.name}'),
              titre: type.libelle,
              detail: type.detail,
              choisi: _a.type == type,
              onTap: () => _changerType(type),
            ),
        ],
      ),
      const SizedBox(height: 22),
      _Titre('Nom'),
      const SizedBox(height: 8),
      TextField(
        key: const Key('new-place-name'),
        controller: _nom,
        focusNode: _nomFocus,
                textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        scrollPadding: const EdgeInsets.only(bottom: 200),
        onChanged: (value) {
          _nomModifie = true;
          _a.nom = value;
          if (_erreurNom != null) setState(() => _erreurNom = null);
        },
        decoration: InputDecoration(
          hintText: 'Ex. Maison, Chalet, Garage',
          errorText: _erreurNom,
          errorMaxLines: 3,
          filled: true,
          fillColor: colors.soft,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      const SizedBox(height: 16),
      Text(
        _a.type.complet
            ? 'L’assistant pose quelques questions (extérieur, étages, pièces, garage) et crée toute la base d’un coup. Tout peut être passé et modifié plus tard.'
            : 'L’assistant demande les étages et les pièces, puis crée la base d’un coup. Tout peut être passé et modifié plus tard.',
        style: colors.body(14, FontWeight.w500, color: colors.mute),
      ),
      if (widget.options.permettreSansAide) ...[
      const SizedBox(height: 16),
      _GrosBouton.contour(
        key: const Key('create-place'),
        label: 'Sans aide : créer seulement ce lieu',
        onPressed: _creerSansAide,
      ),
      ],
    ];
  }

  List<Widget> _etapeExterieur() {
    final a = _a;
    return [
      _OuiNon('Inclure l’extérieur', a.exterieur, (v) => setState(() => a.exterieur = v),
          cle: 'ext'),
      if (a.exterieur) ...[
        _OuiNon('Cour avant', a.courAvant, (v) => setState(() => a.courAvant = v), cle: 'cour-avant'),
        _OuiNon('Cour arrière', a.courArriere, (v) => setState(() => a.courArriere = v),
            cle: 'cour-arriere'),
        _Ligne(
          label: 'Cours sur les côtés',
          largeurMin: 560,
          child: _Segments<int>(
            valeur: a.coursCote,
            choix: const {0: 'Aucune', 1: 'Un côté', 2: 'Les deux'},
            onChanged: (v) => setState(() => a.coursCote = v),
          ),
        ),
        const SizedBox(height: 14),
        _Titre(a.courArriere ? 'Dans la cour arrière' : 'Dans la cour'),
        _OuiNon('Galerie', a.galerie, (v) => setState(() => a.galerie = v), cle: 'galerie'),
        _Compteur('Remises', a.remises, (v) => setState(() => a.remises = v), cle: 'remises'),
        _Compteur('Coffres de rangement', a.coffres, (v) => setState(() => a.coffres = v),
            cle: 'coffres'),
        _OuiNon('Spa', a.spa, (v) => setState(() => a.spa = v), cle: 'spa'),
        _OuiNon('Piscine', a.piscine, (v) => setState(() => a.piscine = v), cle: 'piscine'),
        const SizedBox(height: 14),
        _Titre('Autre'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('ext-autre'),
                controller: _autreExt,
                textCapitalization: TextCapitalization.sentences,
                scrollPadding: const EdgeInsets.only(bottom: 200),
                decoration: const InputDecoration(hintText: 'Ex. Potager, Cabanon'),
                onSubmitted: (_) => _ajouterAutreExt(),
              ),
            ),
            const SizedBox(width: 8),
            _GrosBouton.contour(label: 'Ajouter', onPressed: _ajouterAutreExt, large: false),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final autre in a.autresExterieur)
              InputChip(
                label: Text(autre),
                onDeleted: () => setState(() => a.autresExterieur.remove(autre)),
              ),
          ],
        ),
      ],
    ];
  }

  void _ajouterAutreExt() {
    final texte = _autreExt.text.trim();
    if (texte.isEmpty) return;
    setState(() {
      _a.autresExterieur.add(texte);
      _autreExt.clear();
    });
  }

  List<Widget> _etapeMaison() {
    final a = _a;
    final colors = _Couleurs.of(context);
    return [
      _Compteur(
        'Nombre d’étages (sans le sous-sol)',
        a.etages,
        (v) => setState(() => a.changerEtages(v)),
        min: 1,
        max: 9,
        cle: 'etages',
      ),
      _Compteur(
        'Étages habitables',
        a.habitables,
        (v) => setState(() => a.changerHabitables(v)),
        max: a.etages,
        cle: 'habitables',
      ),
      _OuiNon('Sous-sol', a.sousSol, (v) => setState(() => a.sousSol = v), cle: 'sous-sol'),
      if (a.type.complet) ...[
        _OuiNon('Grenier', a.grenier, (v) => setState(() => a.grenier = v), cle: 'grenier'),
        _OuiNon('Cave (pas forcément habitable)', a.cave, (v) => setState(() => a.cave = v),
            cle: 'cave'),
      ],
      const SizedBox(height: 12),
      Text(
        'À l’étape suivante, vous choisirez les pièces de chaque étage.',
        style: colors.body(14, FontWeight.w500, color: colors.mute),
      ),
    ];
  }

  List<Widget> _etapeNiveau(Niveau niveau) {
    final colors = _Couleurs.of(context);
    return [
      if (!niveau.habitable)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Étage non habitable : ajoutez seulement ce qui sert au rangement.',
            style: colors.body(14, FontWeight.w500, color: colors.mute),
          ),
        ),
      _Titre('Quelles pièces ?'),
      const SizedBox(height: 4),
      for (final type in kTypesPieces)
        _Compteur(
          type.nom,
          niveau.nombre(type),
          (v) => setState(() => niveau.ajuster(type, v)),
          cle: 'piece-${type.id}',
        ),
      if (niveau.pieces.isNotEmpty) ...[
        const SizedBox(height: 18),
        _Titre('Noms et rangements'),
        Text(
          'Facultatif : renommez une pièce ou cochez ses rangements.',
          style: colors.body(14, FontWeight.w500, color: colors.mute),
        ),
        const SizedBox(height: 8),
        for (final piece in niveau.pieces) _cartePiece(piece),
      ],
    ];
  }

  Widget _cartePiece(Piece piece) {
    final colors = _Couleurs.of(context);
    return Card(
      elevation: 0,
      color: colors.soft,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: ValueKey('nom-${identityHashCode(piece)}-${piece.renomme ? '' : piece.nom}'),
              initialValue: piece.nom,
              textCapitalization: TextCapitalization.sentences,
              scrollPadding: const EdgeInsets.only(bottom: 200),
              style: colors.body(16, FontWeight.w700),
              decoration: const InputDecoration(
                labelText: 'Nom de la pièce',
                suffixIcon: Icon(Icons.edit_outlined, size: 18),
              ),
              onChanged: (value) {
                piece.nom = value;
                piece.renomme = true;
              },
            ),
            if (piece.type.sousLieux.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final sous in piece.type.sousLieux)
                    FilterChip(
                      label: Text(sous),
                      selected: piece.sousLieux.contains(sous),
                      onSelected: (on) => setState(() {
                        on ? piece.sousLieux.add(sous) : piece.sousLieux.remove(sous);
                      }),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _etapeGarage() {
    final a = _a;
    return [
      _OuiNon('Y a-t-il un garage ?', a.garage, (v) => setState(() => a.garage = v), cle: 'garage'),
      if (a.garage) ...[
        _Ligne(
          label: 'Le garage est',
          largeurMin: 440,
          child: _Segments<bool>(
            valeur: a.garageAttache,
            choix: const {true: 'Attaché', false: 'Détaché'},
            onChanged: (v) => setState(() => a.garageAttache = v),
          ),
        ),
        _Compteur('Mezzanines', a.mezzanines, (v) => setState(() => a.mezzanines = v),
            cle: 'mezzanines'),
        _Compteur('Murs à utiliser comme zones', a.murs, (v) => setState(() => a.murs = v),
            max: 8, cle: 'murs'),
        _OuiNon('Établi', a.etabli, (v) => setState(() => a.etabli = v), cle: 'etabli'),
        _OuiNon('Armoires', a.armoires, (v) => setState(() => a.armoires = v), cle: 'armoires'),
        _OuiNon('Étagères', a.etageres, (v) => setState(() => a.etageres = v), cle: 'etageres'),
      ],
    ];
  }

  List<Widget> _etapeResume() {
    final colors = _Couleurs.of(context);
    final arbre = _a.arbre();
    return [
      _Titre('Voici ce qui sera créé'),
      const SizedBox(height: 4),
      Text(
        '${arbre.total} lieux. Touchez « Retour » pour changer une réponse.',
        style: colors.body(14, FontWeight.w500, color: colors.mute),
      ),
      const SizedBox(height: 12),
      ArbreDomicileVue(arbre: arbre),
      const SizedBox(height: 18),
      if (widget.options.noteFinale != null)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 20, color: colors.mute),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.options.noteFinale!,
                style: colors.body(14, FontWeight.w500, color: colors.mute),
              ),
            ),
          ],
        ),
    ];
  }
}

// ---------- Petits widgets ----------

class _Titre extends StatelessWidget {
  const _Titre(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(texte, style: _Couleurs.of(context).display(19, FontWeight.w700)),
    );
  }
}

class _Ligne extends StatelessWidget {
  const _Ligne({super.key, required this.label, required this.child, this.largeurMin = 300});

  final String label;
  final Widget child;

  /// Sous cette largeur, le choix passe sous le libellé (écrans étroits).
  final double largeurMin;

  @override
  Widget build(BuildContext context) {
    final colors = _Couleurs.of(context);
    final texte = Text(label, style: colors.body(16, FontWeight.w700));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < largeurMin) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [texte, const SizedBox(height: 6), child],
            );
          }
          return Row(
            children: [
              Expanded(child: texte),
              const SizedBox(width: 8),
              child,
            ],
          );
        },
      ),
    );
  }
}

class _Segments<T> extends StatelessWidget {
  const _Segments({required this.valeur, required this.choix, required this.onChanged});

  final T valeur;
  final Map<T, String> choix;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<T>(
      showSelectedIcon: false,
      style: const ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(56, 48)),
        visualDensity: VisualDensity.standard,
      ),
      segments: [
        for (final entry in choix.entries)
          ButtonSegment<T>(value: entry.key, label: Text(entry.value)),
      ],
      selected: {valeur},
      onSelectionChanged: (choisis) => onChanged(choisis.first),
    );
  }
}

class _OuiNon extends StatelessWidget {
  const _OuiNon(this.label, this.valeur, this.onChanged, {required this.cle});

  final String label;
  final bool valeur;
  final ValueChanged<bool> onChanged;
  final String cle;

  @override
  Widget build(BuildContext context) {
    return _Ligne(
      key: Key('q-$cle'),
      label: label,
      child: _Segments<bool>(
        valeur: valeur,
        choix: const {false: 'Non', true: 'Oui'},
        onChanged: onChanged,
      ),
    );
  }
}

class _Compteur extends StatelessWidget {
  const _Compteur(
    this.label,
    this.valeur,
    this.onChanged, {
    required this.cle,
    this.min = 0,
    this.max = 9,
  });

  final String label;
  final int valeur;
  final ValueChanged<int> onChanged;
  final String cle;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    final colors = _Couleurs.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: colors.body(16, FontWeight.w700))),
          IconButton.filledTonal(
            key: Key('moins-$cle'),
            iconSize: 26,
            constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
            onPressed: valeur > min ? () => onChanged(valeur - 1) : null,
            icon: const Icon(Icons.remove_rounded),
            tooltip: 'Moins',
          ),
          SizedBox(
            width: 44,
            child: Text(
              '$valeur',
              key: Key('valeur-$cle'),
              textAlign: TextAlign.center,
              style: colors.display(20, FontWeight.w800),
            ),
          ),
          IconButton.filledTonal(
            key: Key('plus-$cle'),
            iconSize: 26,
            constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
            onPressed: valeur < max ? () => onChanged(valeur + 1) : null,
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Plus',
          ),
        ],
      ),
    );
  }
}

class _CarteChoix extends StatelessWidget {
  const _CarteChoix({
    super.key,
    required this.titre,
    required this.detail,
    required this.choisi,
    required this.onTap,
  });

  final String titre;
  final String detail;
  final bool choisi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = _Couleurs.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 156,
      child: Material(
        color: choisi ? scheme.primaryContainer : colors.soft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: choisi ? scheme.primary : Colors.transparent, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(titre, style: colors.body(17, FontWeight.w800))),
                    if (choisi) Icon(Icons.check_circle, color: scheme.primary, size: 20),
                  ],
                ),
                const SizedBox(height: 2),
                Text(detail, style: colors.body(13, FontWeight.w500, color: colors.mute)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GrosBouton extends StatelessWidget {
  const _GrosBouton.plein({super.key, required this.label, required this.onPressed})
      : _style = 0,
        large = true;
  const _GrosBouton.contour({
    super.key,
    required this.label,
    required this.onPressed,
    this.large = true,
  }) : _style = 1;
  const _GrosBouton.texte({super.key, required this.label, required this.onPressed})
      : _style = 2,
        large = true;

  final String label;
  final VoidCallback? onPressed;
  final bool large;
  final int _style;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(large ? double.infinity : 0, 56)),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
    final texte = Text(label, textAlign: TextAlign.center);
    return switch (_style) {
      0 => FilledButton(style: style, onPressed: onPressed, child: texte),
      1 => OutlinedButton(style: style, onPressed: onPressed, child: texte),
      _ => TextButton(style: style, onPressed: onPressed, child: texte),
    };
  }
}

/// Styles tirés du thème de l’application hôte.
class _Couleurs {
  _Couleurs(this._theme);

  factory _Couleurs.of(BuildContext context) => _Couleurs(Theme.of(context));

  final ThemeData _theme;

  Color get mute => _theme.colorScheme.onSurfaceVariant;
  Color get soft => _theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55);
  Color get accent => _theme.colorScheme.primary;

  TextStyle display(double size, FontWeight weight) =>
      (_theme.textTheme.titleLarge ?? const TextStyle()).copyWith(fontSize: size, fontWeight: weight);

  TextStyle body(double size, FontWeight weight, {Color? color}) =>
      (_theme.textTheme.bodyLarge ?? const TextStyle())
          .copyWith(fontSize: size, fontWeight: weight, color: color);
}
