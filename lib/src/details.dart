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

/// Petite fenêtre pour changer le nom d’un élément (« Tablette du haut »).
/// Rend vrai si le nom a changé.
Future<bool> renommerMeuble(BuildContext context, Meuble meuble) async {
  final nouveau = await showDialog<String>(
    context: context,
    builder: (context) => _DialogueNom(initial: meuble.nom),
  );
  final propre = nouveau?.trim() ?? '';
  if (propre.isEmpty || propre == meuble.nom) return false;
  meuble
    ..nom = propre
    ..renomme = true;
  return true;
}

class _DialogueNom extends StatefulWidget {
  const _DialogueNom({required this.initial});

  final String initial;

  @override
  State<_DialogueNom> createState() => _DialogueNomState();
}

class _DialogueNomState extends State<_DialogueNom> {
  late final TextEditingController _controleur = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Changer le nom'),
      content: TextField(
        key: const Key('renommer-champ'),
        controller: _controleur,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Ex. Tablette du haut'),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        FilledButton(
          key: const Key('renommer-ok'),
          onPressed: () => Navigator.of(context).pop(_controleur.text),
          child: const Text('OK'),
        ),
      ],
    );
  }
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

  String _cle(String quoi) => '${m.base}-$quoi';

  Future<void> _ouvrir(Meuble enfant) async {
    await ouvrirDetail(
      context,
      enfant,
      chemin: _ici,
      apresType: m.genre == GenreMeuble.armoires ? () => m.renumeroterUnites() : null,
    );
    if (mounted) setState(() {});
  }

  Future<void> _renommer(Meuble enfant) async {
    if (await renommerMeuble(context, enfant) && mounted) setState(() {});
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
                const SizedBox(height: 8),
                TextFormField(
                  key: ValueKey('detail-nom-${identityHashCode(m)}-${m.renomme ? '' : m.nom}'),
                  initialValue: m.nom,
                  textCapitalization: TextCapitalization.sentences,
                  style: colors.body(16, FontWeight.w700),
                  decoration: InputDecoration(
                    labelText: m.genre == GenreMeuble.unite ? 'Nom de l’unité' : 'Nom',
                    suffixIcon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                  onChanged: (value) {
                    m.nom = value;
                    m.renomme = true;
                  },
                ),
                if (m.genre == GenreMeuble.unite) ..._typeUnite(),
                const SizedBox(height: 10),
                ..._questions(colors),
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

  List<Widget> _typeUnite() {
    return [
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
    ];
  }

  Widget _tablettes(_Couleurs colors) {
    final espaces = nomsEspaces(m.espaces.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Compteur(
          'Tablettes',
          m.tablettes,
          (v) => setState(() => m.ajusterTablettes(v)),
          max: 20,
          cle: _cle('tablettes'),
        ),
        Text(
          m.tablettes == 0
              ? 'Chaque tablette crée un espace de plus : 2 tablettes = 3 espaces (Bas, Centre, Haut).'
              : '${m.tablettes} tablette${m.tablettes > 1 ? 's' : ''} = ${m.espaces.length} espaces : ${espaces.join(', ')}.',
          key: Key('${_cle('espaces')}-aide'),
          style: colors.body(13.5, FontWeight.w500, color: colors.mute),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  List<Widget> _questions(_Couleurs colors) {
    void maj(VoidCallback f) => setState(f);
    final tiroirs = _Compteur(
      'Tiroirs',
      m.tiroirs.length,
      (v) => maj(() => m.ajusterTiroirs(v)),
      max: 12,
      cle: _cle('tiroirs'),
    );
    switch (m.genre) {
      case GenreMeuble.bureau:
        return [
          tiroirs,
          _OuiNon('Dessus', m.dessus != null, (v) => maj(() => m.changerDessus(v)), cle: _cle('dessus')),
          _OuiNon('Dessous', m.dessous != null, (v) => maj(() => m.changerDessous(v)), cle: _cle('dessous')),
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
            m.comptoirs.length,
            (v) => maj(() => m.ajusterComptoirs(v)),
            max: 6,
            cle: _cle('comptoirs'),
          ),
        ];
      case GenreMeuble.unite:
        return [_tablettes(colors), tiroirs];
      case GenreMeuble.simple:
        return [
          _tablettes(colors),
          if (m.aDesTringles)
            _Compteur(
              'Tringles',
              m.tringles.length,
              (v) => maj(() => m.ajusterTringles(v)),
              max: 6,
              cle: _cle('tringles'),
            ),
          tiroirs,
          _Compteur(
            'Compartiments',
            m.compartiments.length,
            (v) => maj(() => m.ajusterCompartiments(v)),
            max: 12,
            cle: _cle('compartiments'),
          ),
        ];
    }
  }

  /// Ce qui sera créé à l’intérieur : chaque nom se change (crayon) et chaque
  /// espace, tiroir ou unité se détaille à son tour.
  List<Widget> _liste(_Couleurs colors) {
    final enfants = m.sousRangements;
    if (enfants.isEmpty) {
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
      _Titre('À l’intérieur'),
      Text(
        'Touchez le crayon pour changer un nom (ex. « Tablette du haut »), ou un élément pour le détailler.',
        style: colors.body(14, FontWeight.w500, color: colors.mute),
      ),
      const SizedBox(height: 8),
      for (final enfant in enfants)
        Card(
          key: Key('sous-${enfant.nom}'),
          elevation: 0,
          color: colors.soft,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            contentPadding: const EdgeInsets.only(left: 16, right: 4),
            title: Text(enfant.nom, style: colors.body(16, FontWeight.w700)),
            subtitle: enfant.resume.isEmpty ? null : Text(enfant.resume),
            onTap: () => m.detaillable(enfant) ? _ouvrir(enfant) : _renommer(enfant),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: Key('renommer-${enfant.nom}'),
                  tooltip: 'Changer le nom',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _renommer(enfant),
                ),
                if (m.detaillable(enfant)) const Icon(Icons.chevron_right),
              ],
            ),
          ),
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
