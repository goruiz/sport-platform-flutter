import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/teams/presentation/providers/active_team_notifier.dart';
import 'package:sport_platform/modules/teams/presentation/widgets/active_team_pill.dart';

import '../../support/real_translations.dart';

PlayerModel _playerIn(List<(String, String)> teams, {String? captainOf}) => PlayerModel(
      id: 'ana',
      firstName: 'Ana',
      lastName: 'Pérez',
      email: 'ana@email.com',
      teams: [for (final (id, name) in teams) PlayerTeam(teamId: id, teamName: name, isCaptain: id == captainOf)],
    );

Future<ActiveTeamNotifier> _open(WidgetTester tester, PlayerModel player) async {
  final notifier = ActiveTeamNotifier();
  await tester.runAsync(() => notifier.sync(player));
  await pumpWithRealTranslations(
    tester,
    home: (_) => Scaffold(body: ActiveTeamPill(notifier: notifier, margin: const EdgeInsets.all(16))),
  );
  await tester.pumpAndSettle();
  return notifier;
}

void main() {
  setUpAll(initRealTranslations);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('con varios equipos dice cuál es el activo', (tester) async {
    await _open(tester, _playerIn([('t1', 'Los Tigres'), ('t2', 'Los Pumas')]));

    expect(find.text('Los Tigres'), findsOneWidget);
    expect(find.text('Los Pumas'), findsNothing);
  });

  testWidgets('con un solo equipo no hay nada que cambiar y no se dibuja', (tester) async {
    await _open(tester, _playerIn([('t1', 'Los Tigres')]));

    expect(find.text('Los Tigres'), findsNothing);
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('sin equipos tampoco se dibuja', (tester) async {
    await _open(tester, _playerIn([]));

    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('tocarlo abre la hoja con los equipos, el activo marcado', (tester) async {
    await _open(tester, _playerIn([('t1', 'Los Tigres'), ('t2', 'Los Pumas')], captainOf: 't2'));

    await tester.tap(find.text('Los Tigres'));
    await tester.pumpAndSettle();

    expect(find.text('Cambiar de equipo'), findsOneWidget);
    expect(find.byKey(const ValueKey('team-option-t1')), findsOneWidget);
    expect(find.byKey(const ValueKey('team-option-t2')), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    // Del equipo del que es capitán, lo dice.
    expect(find.text('Capitán'), findsOneWidget);
  });

  testWidgets('elegir otro equipo lo vuelve el activo de la app y cierra la hoja', (tester) async {
    final notifier = await _open(tester, _playerIn([('t1', 'Los Tigres'), ('t2', 'Los Pumas')]));

    await tester.tap(find.text('Los Tigres'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('team-option-t2')));
    await tester.pumpAndSettle();

    expect(notifier.activeTeamId, 't2');
    expect(find.text('Cambiar de equipo'), findsNothing);
    // El indicador ya muestra el nuevo.
    expect(find.text('Los Pumas'), findsOneWidget);
    expect(find.text('Los Tigres'), findsNothing);
  });

  testWidgets('un lector de pantalla lo lee como «Equipo activo: …» y como un botón', (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester, _playerIn([('t1', 'Los Tigres'), ('t2', 'Los Pumas')]));

    final label = find.bySemanticsLabel('Equipo activo: Los Tigres');
    expect(label, findsOneWidget);
    expect(tester.getSemantics(label).flagsCollection.isButton, isTrue);
    semantics.dispose();
  });
}
