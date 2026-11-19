part of 'assistant_screen.dart';

/// Ouvre la page « Détailler » d’un rangement (même style que l’assistant).
/// Chaque sous-rangement se détaille à son tour, un niveau à la fois.
Future<void> ouvrirDetail(
  BuildContext context,
  Meuble meuble, {
  String chemin = '',
  VoidCallback? apresType,
}) {
  meuble.detaille = true;
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => _PageDetail(meuble: meuble, chemin: chemin, apresType: apresType),
    ),
  );
}

class _PageDetail extends StatefulWidget {
  const _PageDetail({required this.meuble, required this.chemin, this.apresType});

  final Meuble meuble;

  /// Où se trouve ce rangement (« Cuisine › Armoires »).
  final String chemin;

  /// Appelé quand le type d’une unité change (le parent renumérote).
  final VoidCallback? apresType;

  @override
  State<_PageDetail> createState() => _PageDetailState();
}

class _PageDetailState extends State<_PageDetail> {
  Meuble get m => widget.meuble;

  String get _ici => widget.chemin.isEmpty ? m.nom : '${widget.chemin} › ${m.nom}';

  String _cle(String quoi) => '${m.nom}-$quoi';

  Future<void> _ouvrir(Meuble enfant) async {
    await ouvrirDetail(
      context,
      enfant,
      chemin: _ici,
      apresType: m.genre == GenreMeuble.armoires ? () => m.renumeroterUnites() : null,
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = _Couleurs.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Détailler · ${m.nom}')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                if (widget.chemin.isNotEmpty)
                  Text(
                    widget.chemin,
                    key: const Key('detail-chemin'),
                    style: colors.body(14, FontWeight.w600, color: colors.mute),
                  ),
                if (m.genre == GenreMeuble.unite) ..._unite(colors) else ..._questions(),
                ..._liste(colors),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: _GrosBouton.plein(
            key: const Key('detail-ok'),
            label: 'Terminé',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  /// Unité d’armoire : son nom, son type, puis ses questions.
  List<Widget> _unite(_Couleurs colors) {
    return [
      const SizedBox(height: 8),
      TextFormField(
        key: ValueKey('unite-nom-${identityHashCode(m)}-${m.renomme ? '' : m.nom}'),
        initialValue: m.nom,
        textCapitalization: TextCapitalization.sentences,
        style: colors.body(16, FontWeight.w700),
        decoration: const InputDecoration(
          labelText: 'Nom de l’unité',
          suffixIcon: Icon(Icons.edit_outlined, size: 18),
        ),
        onChanged: (value) {
          m.nom = value;
          m.renomme = true;
        },
      ),
      const SizedBox(height: 14),
      _Titre('Type d’unité'),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final type in TypeUnite.values)
            ChoiceChip(
              key: Key('type-${type.name}'),
              label: Text(type.libelle),
              selected: m.typeUnite == type,
              onSelected:
                  (_) => setState(() {
                    m.changerType(type);
                    widget.apresType?.call();
                  }),
            ),
        ],
      ),
      const SizedBox(height: 10),
      ..._questions(),
    ];
  }

  List<Widget> _questions() {
    void maj(VoidCallback f) => setState(f);
    switch (m.genre) {
      case GenreMeuble.bureau:
        return [
          _Compteur(
            'Tiroirs',
            m.tiroirs.length,
            (v) => maj(() => m.ajusterTiroirs(v)),
            max: 12,
            cle: _cle('tiroirs'),
          ),
          _OuiNon('Dessus', m.dessus, (v) => maj(() => m.dessus = v), cle: _cle('dessus')),
          _OuiNon('Dessous', m.dessous, (v) => maj(() => m.dessous = v), cle: _cle('dessous')),
        ];
      case GenreMeuble.armoires:
        return [
          _Compteur(
            'Unités',
            m.unites.length,
            (v) => maj(() => m.ajusterUnites(v)),
            max: 30,
            cle: _cle('unites'),
          ),
          _Compteur(
            'Comptoirs',
            m.comptoirs,
            (v) => maj(() => m.comptoirs = v),
            max: 6,
            cle: _cle('comptoirs'),
          ),
        ];
      case GenreMeuble.unite:
        if (m.estGardeManger) {
          return [
            _Compteur(
              'Sections',
              m.sections.length,
              (v) => maj(() => m.ajusterSections(v)),
              min: 1,
              max: 5,
              cle: _cle('sections'),
            ),
          ];
        }
        return [
          _Compteur(
            'Tablettes',
            m.tablettes.length,
            (v) => maj(() => m.ajusterTablettes(v)),
            max: 12,
            cle: _cle('tablettes'),
          ),
          _Compteur(
            'Tiroirs',
            m.tiroirs.length,
            (v) => maj(() => m.ajusterTiroirs(v)),
            max: 12,
            cle: _cle('tiroirs'),
          ),
        ];
      case GenreMeuble.simple:
        return [
          _Compteur(
            'Compartiments',
            m.compartiments.length,
            (v) => maj(() => m.ajusterCompartiments(v)),
            max: 12,
            cle: _cle('compartiments'),
          ),
          _Compteur(
            'Tablettes',
            m.tablettes.length,
            (v) => maj(() => m.ajusterTablettes(v)),
            max: 12,
            cle: _cle('tablettes'),
          ),
          _Compteur(
            'Tiroirs',
            m.tiroirs.length,
            (v) => maj(() => m.ajusterTiroirs(v)),
            max: 12,
            cle: _cle('tiroirs'),
          ),
        ];
    }
  }

  /// Ce qui sera créé à l’intérieur ; chaque ligne se détaille à son tour.
  List<Widget> _liste(_Couleurs colors) {
    final enfants = m.sousRangements;
    // Même ordre que dans l’arbre : dessus et comptoirs, puis le reste,
    // puis dessous.
    final feuilles = <String>[
      if (m.genre == GenreMeuble.bureau && m.dessus) 'Dessus',
      if (m.comptoirs == 1) 'Comptoir',
      if (m.comptoirs > 1)
        for (var i = 1; i <= m.comptoirs; i++) 'Comptoir $i',
    ];
    final apres = <String>[if (m.genre == GenreMeuble.bureau && m.dessous) 'Dessous'];
    if (enfants.isEmpty && feuilles.isEmpty && apres.isEmpty) {
      return [
        const SizedBox(height: 14),
        Text(
          m.genre == GenreMeuble.armoires
              ? 'Touchez + à côté de « Unités » : chaque unité apparaîtra ici pour être nommée et détaillée.'
              : 'Rien à l’intérieur pour l’instant. Tout est facultatif.',
          style: colors.body(14, FontWeight.w500, color: colors.mute),
        ),
      ];
    }
    return [
      const SizedBox(height: 18),
      _Titre(m.genre == GenreMeuble.armoires ? 'Unités et comptoirs' : 'À l’intérieur'),
      Text(
        'Touchez un élément pour le détailler à son tour.',
        style: colors.body(14, FontWeight.w500, color: colors.mute),
      ),
      const SizedBox(height: 8),
      for (final nom in feuilles)
        Card(
          elevation: 0,
          color: colors.soft,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(title: Text(nom, style: colors.body(16, FontWeight.w700))),
        ),
      for (final enfant in enfants)
        Card(
          key: Key('sous-${enfant.nom}'),
          elevation: 0,
          color: colors.soft,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            title: Text(enfant.nom, style: colors.body(16, FontWeight.w700)),
            subtitle: enfant.resume.isEmpty || enfant.resume == enfant.nom ? null : Text(enfant.resume),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _ouvrir(enfant),
          ),
        ),
      for (final nom in apres)
        Card(
          elevation: 0,
          color: colors.soft,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(title: Text(nom, style: colors.body(16, FontWeight.w700))),
        ),
    ];
  }
}

/// Bouton d’un rangement dans une pièce : ▼ nom ▲. Orange dès qu’il y en a
/// au moins un ; les flèches ajoutent ou retirent directement.
class _ElementBouton extends StatelessWidget {
  const _ElementBouton({
    required this.cle,
    required this.label,
    required this.nombre,
    required this.onMoins,
    required this.onPlus,
    required this.onTap,
    this.details = false,
  });

  final String cle;
  final String label;
  final int nombre;
  final VoidCallback onMoins;
  final VoidCallback onPlus;
  final VoidCallback onTap;
  final bool details;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final actif = nombre > 0;
    final fond = actif ? scheme.secondaryContainer : Colors.transparent;
    final texte = actif ? scheme.onSecondaryContainer : scheme.onSurface;
    Widget fleche(IconData icone, String cleFleche, String aide, VoidCallback? action) => IconButton(
      key: Key(cleFleche),
      tooltip: aide,
      onPressed: action,
      icon: Icon(icone),
      iconSize: 24,
      color: texte,
      disabledColor: texte.withValues(alpha: 0.3),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 44),
    );
    return Material(
      color: fond,
      shape: StadiumBorder(side: BorderSide(color: actif ? fond : scheme.outline)),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          fleche(
            Icons.keyboard_arrow_down_rounded,
            'moins-el-$cle',
            'Retirer : $label',
            actif ? onMoins : null,
          ),
          Flexible(
            child: InkWell(
              key: Key('el-$cle'),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        nombre > 1 ? '$label × $nombre' : label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: texte, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                    if (details && actif) ...[
                      const SizedBox(width: 2),
                      Icon(Icons.tune_rounded, size: 16, color: texte),
                    ],
                  ],
                ),
              ),
            ),
          ),
          fleche(Icons.keyboard_arrow_up_rounded, 'plus-el-$cle', 'Ajouter : $label', onPlus),
        ],
      ),
    );
  }
}
