import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ysdad_domicile/ysdad_domicile.dart';

void main() {
  test('les réponses produisent l’arbre attendu', () {
    final r = ReponsesDomicile()
      ..coursCote = 2
      ..galerie = true
      ..remises = 2
      ..garage = true
      ..garageAttache = false
      ..mezzanines = 2
      ..murs = 3
      ..etabli = true
      ..sousSol = true
      ..grenier = true;
    r.changerEtages(2);
    r.changerHabitables(2);
    for (final niveau in r.niveaux) {
      r.preremplir(niveau);
    }
    final arbre = r.arbre();
    expect(arbre.nom, 'Maison');
    expect(arbre.enfants.map((n) => n.nom), ['Extérieur', 'Intérieur', 'Garage']);
    final ext = arbre.enfants[0];
    expect(ext.enfants.map((n) => n.nom),
        ['Cour avant', 'Cour arrière', 'Cour côté gauche', 'Cour côté droit']);
    expect(ext.enfants[1].enfants.map((n) => n.nom), ['Galerie', 'Remise 1', 'Remise 2']);
    final interieur = arbre.enfants[1];
    expect(interieur.enfants.map((n) => n.nom),
        ['Sous-sol', 'Rez-de-chaussée', '2e étage', 'Grenier']);
    final rez = interieur.enfants[1];
    expect(rez.type, TypeNoeud.etage);
    final cuisine = rez.enfants.firstWhere((n) => n.nom == 'Cuisine');
    expect(cuisine.type, TypeNoeud.piece);
    expect(cuisine.enfants.map((n) => n.nom), ['Armoires', 'Tiroirs', 'Tiroir sous la cuisinière']);
    expect(rez.enfants.firstWhere((n) => n.nom == 'Entrée').enfants.single.nom, 'Garde-robe');
    expect(rez.enfants.firstWhere((n) => n.nom == 'Escalier').enfants, isEmpty);
    expect(arbre.parcourir().any((e) => e.noeud.nom.contains('clés')), isFalse);
    final haut = interieur.enfants[2];
    expect(haut.enfants.map((n) => n.nom), ['Salle de bain', 'Chambre 1', 'Chambre 2']);
    expect(haut.enfants.first.enfants.single.nom, 'Armoires de la vanité');
    expect(haut.enfants[1].enfants.single.nom, 'Garde-robe');
    final garage = arbre.enfants[2];
    expect(garage.description, 'Détaché de la maison');
    expect(garage.enfants.map((n) => n.nom),
        ['Mezzanine 1', 'Mezzanine 2', 'Mur 1', 'Mur 2', 'Mur 3', 'Établi']);
    expect(garage.enfants.first.type, TypeNoeud.rangement);

    final copie = NoeudDomicile.fromJson(arbre.toJson());
    expect(copie.total, arbre.total);
  });

  test('tout passer ne crée pas d’« Intérieur » vide', () {
    final r = ReponsesDomicile()..exterieur = false;
    expect(r.arbre().total, 1);
    r.changerEtages(3);
    expect(r.habitables, 3);
  });

  test('renommer une pièce la garde hors de la renumérotation', () {
    final niveau = Niveau('etage-1', 'Rez-de-chaussée');
    final chambre = typePiece('chambre');
    niveau.ajuster(chambre, 2);
    niveau.pieces.first
      ..nom = 'Chambre de Léa'
      ..renomme = true;
    niveau.ajuster(chambre, 3);
    expect(niveau.pieces.map((p) => p.nom), ['Chambre de Léa', 'Chambre 2', 'Chambre 3']);
    niveau.ajuster(chambre, 1);
    expect(niveau.pieces.single.nom, 'Chambre de Léa');
  });

  testWidgets('sans aide : un nom vide affiche une erreur qui reste', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    ResultatDomicile? resultat;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => resultat = await ouvrirAssistantDomicile(context),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('Maison'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('new-place-name')), '');
    await tester.tap(find.byKey(const Key('create-place')));
    await tester.pump();
    const erreur = 'Écrivez le nom du lieu, ou choisissez un type ci-dessus.';
    expect(find.text(erreur), findsOneWidget);
    await tester.pump(const Duration(seconds: 8));
    expect(find.text(erreur), findsOneWidget);
    await tester.enterText(find.byKey(const Key('new-place-name')), 'Garage');
    await tester.pump();
    expect(find.text(erreur), findsNothing);
    await tester.tap(find.byKey(const Key('create-place')));
    await tester.pumpAndSettle();
    expect(resultat?.sansAide, isTrue);
    expect(resultat?.arbre.nom, 'Garage');
    expect(resultat?.arbre.enfants, isEmpty);
  });

  testWidgets('parcours complet avec le garage à deux mezzanines', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    ResultatDomicile? resultat;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => resultat = await ouvrirAssistantDomicile(context),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    Future<void> suivant() async {
      await tester.tap(find.byKey(const Key('assistant-next')));
      await tester.pumpAndSettle();
    }

    await suivant(); // type → extérieur
    expect(find.text('Extérieur'), findsOneWidget);
    await tester.tap(find.byKey(const Key('plus-remises')));
    await tester.pump();
    await suivant(); // → maison
    await tester.tap(find.byKey(const Key('plus-etages')));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('valeur-etages'))).data, '2');
    await suivant(); // → rez
    expect(find.text('Pièces · Rez-de-chaussée'), findsOneWidget);
    await suivant(); // → 2e
    expect(find.text('Pièces · 2e étage'), findsOneWidget);
    await suivant(); // → garage
    await tester.tap(find.descendant(of: find.byKey(const Key('q-garage')), matching: find.text('Oui')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('plus-mezzanines')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('plus-mezzanines')));
    await tester.pump();
    await suivant(); // → résumé
    expect(find.text('Voici ce qui sera créé'), findsOneWidget);
    await tester.tap(find.byKey(const Key('assistant-create')));
    await tester.pumpAndSettle();
    expect(resultat, isNotNull);
    final garage = resultat!.arbre.enfants.last;
    expect(garage.nom, 'Garage');
    expect(garage.enfants.map((n) => n.nom), ['Mezzanine 1', 'Mezzanine 2']);
  });

  testWidgets('le retour système recule d’une étape', (tester) async {
    var ferme = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              await ouvrirAssistantDomicile(context);
              ferme = true;
            },
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('assistant-next')));
    await tester.pumpAndSettle();
    expect(find.text('Extérieur'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Ajouter un lieu'), findsOneWidget);
    expect(ferme, isFalse);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(ferme, isTrue);
  });

  test('les contenants ajoutés suivent les rangements cochés, sans doublon', () {
    final piece = Piece(typePiece('cuisine'), 'Cuisine');
    expect(piece.ajouterContenant('Tiroir'), 'Tiroir');
    expect(piece.ajouterContenant('Tiroir'), 'Tiroir 2');
    expect(piece.ajouterContenant('  Coffre à outils '), 'Coffre à outils');
    expect(piece.ajouterContenant('Armoires'), 'Armoires 2');
    expect(piece.rangements,
        ['Armoires', 'Tiroirs', 'Tiroir sous la cuisinière', 'Tiroir', 'Tiroir 2', 'Coffre à outils', 'Armoires 2']);
    expect(kContenants, containsAll(['Tablette', 'Frigo', 'Congélo', 'Alcôve', 'Coffre', 'Penderie']));
  });

  testWidgets('« + Contenant » ajoute d’un toucher ou au clavier', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    ResultatDomicile? resultat;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => resultat = await ouvrirAssistantDomicile(context),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    Future<void> suivant() async {
      await tester.tap(find.byKey(const Key('assistant-next')));
      await tester.pumpAndSettle();
    }

    await suivant(); // extérieur
    await suivant(); // maison
    await suivant(); // rez
    final bouton = find.byKey(const Key('plus-contenant-Salon'));
    await tester.scrollUntilVisible(bouton, 300, scrollable: find.byType(Scrollable).first);
    await tester.runAsync(() => Scrollable.ensureVisible(tester.element(bouton), alignment: 0.5));
    await tester.pumpAndSettle();
    await tester.tap(bouton);
    await tester.pumpAndSettle();
    expect(find.text('Contenant · Salon'), findsOneWidget);
    await tester.tap(find.byKey(const Key('contenant-Frigo')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ajoute-Salon-Frigo')), findsOneWidget);
    await tester.runAsync(() => Scrollable.ensureVisible(tester.element(bouton), alignment: 0.5));
    await tester.pumpAndSettle();
    await tester.tap(bouton);
    await tester.pumpAndSettle();
    expect(find.text('Contenant · Salon'), findsOneWidget, reason: 'deuxième ouverture');
    await tester.tap(find.byKey(const Key('contenant-ajouter')));
    await tester.pump();
    expect(find.text('Écrivez un nom, ou touchez un contenant ci-dessous.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('contenant-libre')), 'Coffre à jeux');
    await tester.tap(find.byKey(const Key('contenant-ajouter')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ajoute-Salon-Coffre à jeux')), findsOneWidget);
    await suivant(); // garage
    await suivant(); // résumé
    await tester.tap(find.byKey(const Key('assistant-create')));
    await tester.pumpAndSettle();
    final salon = resultat!.arbre.parcourir().firstWhere((e) => e.noeud.nom == 'Salon').noeud;
    expect(salon.enfants.map((n) => n.nom), ['Frigo', 'Coffre à jeux']);
    expect(salon.enfants.first.type, TypeNoeud.rangement);
  });
}
