import 'package:flutter/material.dart';

import 'reponses.dart';

/// Ouvre la liste des contenants (« + Contenant ») : un seul toucher ajoute
/// le contenant choisi, ou on tape un nom au clavier. Renvoie le nom, ou
/// `null` si la personne ferme la liste.
///
/// [contenants] permet à l’appli hôte de proposer sa propre liste.
Future<String?> choisirContenant(
  BuildContext context, {
  String titre = 'Ajouter un contenant',
  List<String> contenants = kContenants,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => _ListeContenants(titre: titre, contenants: contenants),
  );
}

class _ListeContenants extends StatefulWidget {
  const _ListeContenants({required this.titre, required this.contenants});

  final String titre;
  final List<String> contenants;

  @override
  State<_ListeContenants> createState() => _ListeContenantsState();
}

class _ListeContenantsState extends State<_ListeContenants> {
  final _libre = TextEditingController();
  String? _erreur;

  @override
  void dispose() {
    _libre.dispose();
    super.dispose();
  }

  void _valider() {
    final nom = _libre.text.trim();
    if (nom.isEmpty) {
      setState(() => _erreur = 'Écrivez un nom, ou touchez un contenant ci-dessous.');
      return;
    }
    Navigator.of(context).pop(nom);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bas = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bas),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.titre,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Écrivez un nom, ou touchez un contenant ci-dessous pour l’ajouter.',
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('contenant-libre'),
                    controller: _libre,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _valider(),
                    onChanged: (_) {
                      if (_erreur != null) setState(() => _erreur = null);
                    },
                    decoration: InputDecoration(
                      hintText: 'Autre contenant, ex. Coffre à outils',
                      errorText: _erreur,
                      errorMaxLines: 2,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    key: const Key('contenant-ajouter'),
                    onPressed: _valider,
                    child: const Text('Ajouter'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final nom in widget.contenants)
                  ActionChip(
                    key: Key('contenant-$nom'),
                    label: Text(nom),
                    labelStyle: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    backgroundColor: Color.alphaBlend(
                      scheme.primary.withValues(alpha: 0.08),
                      scheme.surface,
                    ),
                    side: BorderSide(color: scheme.primary.withValues(alpha: 0.35)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    onPressed: () => Navigator.of(context).pop(nom),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
