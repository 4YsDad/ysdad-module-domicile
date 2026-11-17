import 'package:flutter/material.dart';

import 'modele.dart';

/// Affiche un arbre de domicile en retrait (lecture seule).
class ArbreDomicileVue extends StatelessWidget {
  const ArbreDomicileVue({super.key, required this.arbre});

  final NoeudDomicile arbre;

  static IconData icone(TypeNoeud type, {bool racine = false}) {
    if (racine) return Icons.home_outlined;
    return switch (type) {
      TypeNoeud.lieu => Icons.home_work_outlined,
      TypeNoeud.exterieur => Icons.park_outlined,
      TypeNoeud.etage => Icons.layers_outlined,
      TypeNoeud.piece => Icons.meeting_room_outlined,
      TypeNoeud.rangement => Icons.inventory_2_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyLarge ?? const TextStyle();
    final mute = theme.colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (:noeud, :profondeur) in arbre.parcourir())
          Padding(
            padding: EdgeInsets.only(left: 22.0 * profondeur, top: 4, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icone(noeud.type, racine: profondeur == 0),
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: noeud.nom,
                      style: base.copyWith(
                        fontSize: profondeur == 0 ? 17 : 15,
                        fontWeight: profondeur <= 1 ? FontWeight.w800 : FontWeight.w600,
                      ),
                      children: [
                        if (noeud.description != null)
                          TextSpan(
                            text: '  ${noeud.description}',
                            style: base.copyWith(fontSize: 13, color: mute),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Montre un arbre produit par une autre source (p. ex. une future analyse
/// vidéo) et demande confirmation. Rend le résultat, ou `null`.
Future<ResultatDomicile?> confirmerArbreDomicile(
  BuildContext context,
  NoeudDomicile arbre, {
  String source = 'externe',
}) {
  return Navigator.of(context).push<ResultatDomicile>(
    MaterialPageRoute<ResultatDomicile>(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Résumé')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [ArbreDomicileVue(arbre: arbre)],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              onPressed: () => Navigator.of(context).pop(
                ResultatDomicile(arbre: arbre, source: source),
              ),
              child: Text('Créer ${arbre.total} lieux'),
            ),
          ),
        ),
      ),
    ),
  );
}
