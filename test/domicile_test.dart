import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ysdad_domicile/ysdad_domicile.dart';

void main() {
  test('les réponses produisent l’arbre attendu', () {
    final r =
        ReponsesDomicile()
          ..coursCote = 2
          ..galerie = true
          ..remises = 2
          ..garage = true
          ..garageAttache = false
          ..mezzanines = 2
          ..murs = 3
          ..etabli = true
          ..grenier = true
          ..cave = true;
    r.changerEtages(3);
    r
      ..nommerEtage(0, 'Sous-sol')
      ..nommerEtage(1, 'Rez-de-chaussée')
      ..nommerEtage(2, 'Deuxième étage');
    for (final niveau in r.niveaux) {
      r.preremplir(niveau);
    }
    final arbre = r.arbre();
    expect(arbre.nom, 'Maison');
    expect(arbre.enfants.map((n) => n.nom), ['Extérieur', 'Intérieur', 'Garage']);
    final ext = arbre.enfants[0];
    expect(ext.enfants.map((n) => n.nom), [
      'Cour avant',
      'Cour arrière',
      'Cour côté gauche',
      'Cour côté droit',
    ]);
    expect(ext.enfants[1].enfants.map((n) => n.nom), ['Galerie', 'Remise 1', 'Remise 2']);
    final interieur = arbre.enfants[1];
    expect(interieur.enfants.map((n) => n.nom), [
      'Sous-sol',
      'Rez-de-chaussée',
      'Deuxième étage',
      'Grenier',
      'Cave de service',
    ]);
    expect(interieur.enfants[0].enfants, isEmpty, reason: 'sous-sol : pas de pièces imposées');
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
    expect(garage.enfants.map((n) => n.nom), [
      'Mezzanine 1',
      'Mezzanine 2',
      'Mur 1',
      'Mur 2',
      'Mur 3',
      'Établi',
    ]);
    expect(garage.enfants.first.type, TypeNoeud.rangement);

    final copie = NoeudDomicile.fromJson(arbre.toJson());
    expect(copie.total, arbre.total);
  });

  test('tout passer ne crée pas d’« Intérieur » vide', () {
    final r = ReponsesDomicile()..exterieur = false;
    expect(r.arbre().total, 1);
    r.changerEtages(3);
    expect(r.nomsEtages, ['Rez-de-chaussée', 'Deuxième étage', 'Troisième étage']);
    r.nommerEtage(1, 'Premier étage');
    r.changerEtages(2);
    expect(r.niveaux.map((n) => n.nom), ['Rez-de-chaussée', 'Premier étage']);
    r.changerEtages(1);
    expect(r.niveaux.length, 1, reason: 'aucun étage en double');
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
          builder:
              (context) => TextButton(
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
          builder:
              (context) => TextButton(
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
    expect(find.text('Pièces · Deuxième étage'), findsOneWidget);
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
          builder:
              (context) => TextButton(
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

  test('les contenants ajoutés suivent les rangements, sans doublon', () {
    final piece = Piece(typePiece('cuisine'), 'Cuisine');
    expect(piece.ajouterContenant('Tiroir')!.nom, 'Tiroir');
    expect(piece.ajouterContenant('Tiroir')!.nom, 'Tiroir 2');
    expect(piece.ajouterContenant('  Coffre à outils ')!.nom, 'Coffre à outils');
    expect(piece.ajouterContenant('Armoires')!.nom, 'Armoire 2');
    expect(piece.rangements, [
      'Armoire 1',
      'Armoire 2',
      'Tiroirs',
      'Tiroir sous la cuisinière',
      'Tiroir 1',
      'Tiroir 2',
      'Coffre à outils',
    ]);
    expect(
      kContenants,
      containsAll(['Tablette', 'Frigo', 'Congélo', 'Alcôve', 'Coffre', 'Penderie', 'Comptoir']),
    );
    expect(kContenants, isNot(contains('Crédence')));
  });

  test('les flèches ajoutent et retirent ; un ajout manuel disparaît à 0', () {
    final piece = Piece(typePiece('chambre'), 'Chambre');
    final commode = piece.groupe('Commode')!;
    expect(commode.nombre, 0);
    piece.ajuster(commode, 2);
    expect(piece.rangements, ['Garde-robe', 'Commode 1', 'Commode 2']);
    piece.ajuster(commode, 0);
    expect(piece.groupe('Commode'), isNotNull, reason: 'suggéré : reste proposé');
    piece.ajouterContenant('Valise');
    piece.ajuster(piece.groupe('Valise')!, 0);
    expect(piece.groupe('Valise'), isNull);
  });

  test('bureau : tiroirs numérotés, dessus et dessous dans l’arbre', () {
    final bureau = Meuble('Bureau (meuble)');
    expect(bureau.genre, GenreMeuble.bureau);
    bureau
      ..ajusterTiroirs(3)
      ..changerDessus(true)
      ..changerDessous(true);
    bureau.tiroirs[1].ajusterCompartiments(2);
    final noeud = bureau.noeud();
    expect(noeud.enfants.map((n) => n.nom), ['Dessus', 'Tiroir 1', 'Tiroir 2', 'Tiroir 3', 'Dessous']);
    expect(noeud.enfants[2].enfants.map((n) => n.nom), ['Compartiment 1', 'Compartiment 2']);
    bureau.ajusterTiroirs(1);
    expect(bureau.noeud().enfants.map((n) => n.nom), ['Dessus', 'Tiroir 1', 'Dessous']);
  });

  test('règle des espaces : N tablettes donnent N + 1 espaces nommés du bas vers le haut', () {
    expect(nomsEspaces(1), isEmpty);
    expect(nomsEspaces(2), ['Bas', 'Haut']);
    expect(nomsEspaces(3), ['Bas', 'Centre', 'Haut']);
    expect(nomsEspaces(4), ['Bas', 'Centre-bas', 'Centre-haut', 'Haut']);
    expect(nomsEspaces(5), ['Bas', 'Centre-bas', 'Centre', 'Centre-haut', 'Haut']);
    expect(nomsEspaces(7), ['Bas', 'Centre 1', 'Centre 2', 'Centre 3', 'Centre 4', 'Centre 5', 'Haut']);
    final biblio = Meuble('Bibliothèque');
    expect(biblio.noeud().enfants, isEmpty, reason: 'sans tablette : un seul espace, le meuble');
    biblio.ajusterTablettes(2);
    expect(biblio.noeud().enfants.map((n) => n.nom), ['Bas', 'Centre', 'Haut']);
    biblio.espaces.last
      ..nom = 'Tablette du haut'
      ..renomme = true;
    biblio.ajusterTablettes(3);
    expect(biblio.noeud().enfants.map((n) => n.nom), [
      'Bas',
      'Centre-bas',
      'Centre-haut',
      'Tablette du haut',
    ]);
  });

  test('garde-robe : tringles ; les autres rangements n’en ont pas', () {
    final garde = Meuble('Garde-robe 2', base: 'Garde-robe');
    expect(garde.aDesTringles, isTrue);
    expect(Meuble('Penderie').aDesTringles, isTrue);
    expect(Meuble('Commode').aDesTringles, isFalse);
    garde
      ..ajusterTablettes(1)
      ..ajusterTringles(2);
    expect(garde.noeud().enfants.map((n) => n.nom), ['Bas', 'Haut', 'Tringle 1', 'Tringle 2']);
  });

  test('armoires : unités par type, garde-manger selon la règle des espaces, comptoirs', () {
    final armoires = Meuble('Armoires');
    expect(armoires.genre, GenreMeuble.armoires);
    armoires
      ..ajusterUnites(3)
      ..ajusterComptoirs(1);
    armoires.unites[0].changerType(TypeUnite.gardeManger);
    armoires.unites[2].changerType(TypeUnite.uniteTiroirs);
    armoires.renumeroterUnites();
    expect(armoires.unites.map((u) => u.nom), ['Garde-manger', 'Armoire du bas', 'Unité de tiroirs']);
    expect(armoires.unites[0].espaces.map((s) => s.nom), ['Bas', 'Centre', 'Haut']);
    armoires.unites[0].ajusterTablettes(4);
    expect(armoires.unites[0].espaces.map((s) => s.nom), [
      'Bas',
      'Centre-bas',
      'Centre',
      'Centre-haut',
      'Haut',
    ]);
    armoires.unites[1].ajusterTablettes(1);
    final noeud = armoires.noeud();
    expect(noeud.enfants.map((n) => n.nom), [
      'Comptoir',
      'Garde-manger',
      'Armoire du bas',
      'Unité de tiroirs',
    ]);
    expect(noeud.enfants[2].enfants.map((n) => n.nom), ['Bas', 'Haut']);
    expect(noeud.enfants[3].enfants.map((n) => n.nom), ['Tiroir 1', 'Tiroir 2', 'Tiroir 3']);
  });

  testWidgets('« + Contenant » ajoute d’un toucher ou au clavier', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    ResultatDomicile? resultat;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder:
              (context) => TextButton(
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
    expect(find.byKey(const Key('el-Salon-Frigo')), findsOneWidget);
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
    expect(find.byKey(const Key('el-Salon-Coffre à jeux')), findsOneWidget);
    await suivant(); // garage
    await suivant(); // résumé
    await tester.tap(find.byKey(const Key('assistant-create')));
    await tester.pumpAndSettle();
    final salon = resultat!.arbre.parcourir().firstWhere((e) => e.noeud.nom == 'Salon').noeud;
    expect(salon.enfants.map((n) => n.nom), ['Frigo', 'Coffre à jeux']);
    expect(salon.enfants.first.type, TypeNoeud.rangement);
  });

  testWidgets('flèches et pages « Détailler » (bureau, armoires, unité)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    ResultatDomicile? resultat;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder:
              (context) => TextButton(
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

    Future<void> toucher(Finder f) async {
      await tester.scrollUntilVisible(f, 300, scrollable: find.byType(Scrollable).first);
      await tester.runAsync(() => Scrollable.ensureVisible(tester.element(f), alignment: 0.5));
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    await suivant(); // extérieur
    await suivant(); // maison
    await suivant(); // rez

    // Flèches : deux garde-robes dans l’entrée, sans changer d’écran.
    await toucher(find.byKey(const Key('plus-el-Entrée-Garde-robe')));
    expect(find.text('Garde-robe × 2'), findsOneWidget);
    expect(find.text('Pièces · Rez-de-chaussée'), findsOneWidget);

    // Armoires de la cuisine : toucher ouvre « Détailler ».
    await toucher(find.byKey(const Key('el-Cuisine-Armoires')));
    expect(find.text('Détailler · Armoires'), findsOneWidget);
    await tester.tap(find.byKey(const Key('plus-Armoires-unites')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('plus-Armoires-unites')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('plus-Armoires-comptoirs')));
    await tester.pumpAndSettle();
    await toucher(find.byKey(const Key('sous-Armoire du bas 1')));
    expect(find.text('Détailler · Armoire du bas 1'), findsOneWidget);
    await toucher(find.byKey(const Key('type-gardeManger')));
    expect(find.byKey(const Key('Armoire du bas-espaces-aide')), findsOneWidget);
    await toucher(find.byKey(const Key('detail-ok')));
    expect(find.byKey(const Key('sous-Garde-manger')), findsOneWidget);
    expect(find.byKey(const Key('sous-Armoire du bas')), findsOneWidget);
    await toucher(find.byKey(const Key('detail-ok')));

    // Bureau ajouté par « + Contenant » : sa page s’ouvre tout de suite.
    await toucher(find.byKey(const Key('plus-contenant-Salon')));
    await tester.tap(find.byKey(const Key('contenant-Bureau')));
    await tester.pumpAndSettle();
    expect(find.text('Détailler · Bureau'), findsOneWidget);
    await tester.tap(find.byKey(const Key('plus-Bureau-tiroirs')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('plus-Bureau-tiroirs')));
    await tester.pumpAndSettle();
    await toucher(find.descendant(of: find.byKey(const Key('q-Bureau-dessus')), matching: find.text('Oui')));
    await toucher(find.byKey(const Key('sous-Tiroir 2')));
    expect(find.text('Détailler · Tiroir 2'), findsOneWidget);
    await tester.tap(find.byKey(const Key('plus-Tiroir-compartiments')));
    await tester.pumpAndSettle();
    await toucher(find.byKey(const Key('detail-ok')));
    await toucher(find.byKey(const Key('detail-ok')));

    await suivant(); // garage
    await suivant(); // résumé
    await tester.tap(find.byKey(const Key('assistant-create')));
    await tester.pumpAndSettle();
    final noeuds = resultat!.arbre.parcourir().map((e) => e.noeud).toList();
    NoeudDomicile n(String nom) => noeuds.firstWhere((x) => x.nom == nom);
    expect(n('Entrée').enfants.map((x) => x.nom), containsAll(['Garde-robe 1', 'Garde-robe 2']));
    expect(n('Armoires').enfants.map((x) => x.nom), ['Comptoir', 'Garde-manger', 'Armoire du bas']);
    expect(n('Garde-manger').enfants.map((x) => x.nom), ['Bas', 'Centre', 'Haut']);
    expect(n('Bureau').enfants.map((x) => x.nom), ['Dessus', 'Tiroir 1', 'Tiroir 2']);
    expect(n('Tiroir 2').enfants.map((x) => x.nom), ['Compartiment 1']);
  });

  testWidgets('étages nommés, tringles, espaces et noms modifiables', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    ResultatDomicile? resultat;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder:
              (context) => TextButton(
                onPressed: () async => resultat = await ouvrirAssistantDomicile(context),
                child: const Text('go'),
              ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    Future<void> toucher(Finder f) async {
      await tester.scrollUntilVisible(f, 300, scrollable: find.byType(Scrollable).first);
      await tester.runAsync(() => Scrollable.ensureVisible(tester.element(f), alignment: 0.5));
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    Future<void> suivant() async {
      await tester.tap(find.byKey(const Key('assistant-next')));
      await tester.pumpAndSettle();
    }

    await suivant(); // extérieur
    await suivant(); // maison
    expect(find.text('Combien d’étages habitables y a-t-il ?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('plus-etages')));
    await tester.pumpAndSettle();
    await toucher(find.byKey(const Key('etage-0-Sous-sol')));
    await toucher(find.byKey(const Key('etage-1-Rez-de-chaussée')));
    expect(find.text('Cave de service'), findsOneWidget);
    await suivant();
    expect(find.text('Pièces · Sous-sol'), findsOneWidget);
    await suivant();
    expect(find.text('Pièces · Rez-de-chaussée'), findsOneWidget);
    await toucher(find.byKey(const Key('el-Entrée-Garde-robe')));
    expect(find.text('Détailler · Garde-robe'), findsOneWidget);
    await tester.tap(find.byKey(const Key('plus-Garde-robe-tringles')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('plus-Garde-robe-tablettes')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('plus-Garde-robe-tablettes')));
    await tester.pumpAndSettle();
    expect(find.text('2 tablettes = 3 espaces : Bas, Centre, Haut.'), findsOneWidget);
    await toucher(find.byKey(const Key('renommer-Haut')));
    await tester.enterText(find.byKey(const Key('renommer-champ')), 'Tablette des chapeaux');
    await tester.tap(find.byKey(const Key('renommer-ok')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Tablette des chapeaux'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await toucher(find.byKey(const Key('detail-ok')));
    await suivant(); // garage
    await suivant(); // résumé
    await tester.tap(find.byKey(const Key('assistant-create')));
    await tester.pumpAndSettle();
    final interieur = resultat!.arbre.enfants.firstWhere((n) => n.nom == 'Intérieur');
    expect(interieur.enfants.map((n) => n.nom).take(2), ['Sous-sol', 'Rez-de-chaussée']);
    final garde = resultat!.arbre.parcourir().firstWhere((e) => e.noeud.nom == 'Garde-robe').noeud;
    expect(garde.enfants.map((n) => n.nom), ['Bas', 'Centre', 'Tablette des chapeaux', 'Tringle 1']);
  });
}
