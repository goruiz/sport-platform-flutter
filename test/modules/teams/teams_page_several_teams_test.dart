import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/teams_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/team_model.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/teams/presentation/pages/teams_page.dart';
import 'package:sport_platform/modules/teams/presentation/providers/active_team_notifier.dart';

import '../../support/real_translations.dart';

/// Un jugador puede jugar en varios equipos, uno por organización: la pantalla los ofrece en un carrusel de tarjetas (el
/// último al que entró primero), muestra el detalle del elegido y ese equipo pasa a ser el activo de toda la app.
const _tigres = TeamModel(id: 'team-1', name: 'Los Tigres');
const _pumas = TeamModel(id: 'team-2', name: 'Los Pumas');

PlayerModel _member(String name, {bool isCaptain = false}) =>
    PlayerModel(id: name.toLowerCase(), firstName: name, lastName: 'Gómez', email: '${name.toLowerCase()}@email.com', isCaptain: isCaptain);

/// El backend de mentira: Ana es capitana de Los Tigres (el último al que entró) y jugadora de Los Pumas; al abandonar uno
/// se queda con el otro.
class _FakePlayersService extends PlayersService {
  final List<PlayerTeam> _teams;
  final List<({String playerId, String? teamId})> left = [];

  _FakePlayersService({List<PlayerTeam>? teams})
      : _teams = List.of(
          teams ??
              const [
                PlayerTeam(teamId: 'team-1', teamName: 'Los Tigres', isCaptain: true),
                PlayerTeam(teamId: 'team-2', teamName: 'Los Pumas'),
              ],
        );

  @override
  Future<PlayerModel?> getCurrent() async => PlayerModel(
        id: 'ana',
        firstName: 'Ana',
        lastName: 'Pérez',
        email: 'ana@email.com',
        teamId: _teams.isEmpty ? null : _teams.first.teamId,
        teamName: _teams.isEmpty ? null : _teams.first.teamName,
        teams: List.of(_teams),
      );

  @override
  Future<List<PlayerModel>> getByTeamId(String teamId) async => switch (teamId) {
        'team-1' => [_member('Ana', isCaptain: true), _member('Luis')],
        'team-2' => [_member('Ana'), _member('Eva', isCaptain: true)],
        _ => [_member('Ana')],
      };

  @override
  Future<PlayerModel> removeFromTeam(String playerId, {String? teamId}) async {
    left.add((playerId: playerId, teamId: teamId));
    _teams.removeWhere((team) => team.teamId == teamId);
    return (await getCurrent())!;
  }
}

/// Solo conoce Los Tigres y Los Pumas: cualquier otro id es un equipo que ya no existe.
class _FakeTeamsService extends TeamsService {
  @override
  Future<TeamModel?> getById(String id) async => switch (id) {
        'team-1' => _tigres,
        'team-2' => _pumas,
        _ => null,
      };
}

const _menuItem = MenuItemModel(id: 'menu-teams', name: 'Equipo');

Future<void> _openTeamsPage(WidgetTester tester, _FakePlayersService players) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  getIt.registerSingleton<PlayersService>(players);
  getIt.registerSingleton<TeamsService>(_FakeTeamsService());
  getIt.registerSingleton<ActiveTeamNotifier>(ActiveTeamNotifier());
  await pumpWithRealTranslations(tester, home: (_) => const TeamsPage(item: _menuItem));
  await tester.pumpAndSettle();
}

Finder _card(String teamId) => find.byKey(ValueKey('team-card-$teamId'));

Finder _detail(String teamId) => find.byKey(ValueKey('team-detail-$teamId'));

/// Las flechas bajo el carrusel (su tooltip es lo que lee un lector de pantalla).
Finder get _nextArrow => find.byTooltip('Equipo siguiente');

Finder get _previousArrow => find.byTooltip('Equipo anterior');

Future<void> _goToNextTeam(WidgetTester tester) async {
  await tester.tap(_nextArrow);
  await tester.pumpAndSettle();
}

/// Avanza la pantalla alternando fotogramas con turnos del bucle real. La primera lectura de la pantalla nace en
/// `initState`, que `pumpWithRealTranslations` ejecuta en la zona de tiempo real: una segunda lectura (tras abandonar un
/// equipo) espera lo que esa zona dejó pendiente, y `pumpAndSettle` no le da el turno.
Future<void> _settleAfterReload(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 300));
  }
  await tester.pumpAndSettle();
}

Future<void> _tapLeaveButton(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(OutlinedButton, 'Abandonar equipo'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(initRealTranslations);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(getIt.reset);

  testWidgets('quien juega en varios equipos ve su tarjeta y el detalle del último al que entró', (tester) async {
    await _openTeamsPage(tester, _FakePlayersService());

    expect(find.text('Tus equipos (2)'), findsOneWidget);
    expect(find.textContaining('La app muestra la información del equipo que elijas'), findsOneWidget);
    expect(_card('team-1'), findsOneWidget);
    expect(_detail('team-1'), findsOneWidget);
    expect(_detail('team-2'), findsNothing);
    expect(find.text('Luis Gómez'), findsOneWidget);
    expect(find.text('Eva Gómez'), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);
    // Una sola acción de abandonar: la del equipo elegido.
    expect(find.widgetWithText(OutlinedButton, 'Abandonar equipo'), findsOneWidget);
  });

  testWidgets('la tarjeta del equipo elegido queda dentro de los márgenes de la pantalla', (tester) async {
    await _openTeamsPage(tester, _FakePlayersService());

    final rect = tester.getRect(_card('team-1'));
    expect(rect.left, 16);
    expect(rect.right, 800 - 16);
  });

  testWidgets('las flechas pasan de un equipo al otro, y la de un extremo se apaga', (tester) async {
    await _openTeamsPage(tester, _FakePlayersService());
    expect(tester.widget<IconButton>(find.ancestor(of: find.byIcon(Icons.chevron_left_rounded), matching: find.byType(IconButton))).onPressed, isNull);

    await _goToNextTeam(tester);

    expect(_detail('team-2'), findsOneWidget);
    expect(_detail('team-1'), findsNothing);
    expect(find.text('Eva Gómez'), findsOneWidget);
    expect(find.text('Luis Gómez'), findsNothing);
    expect(tester.widget<IconButton>(find.ancestor(of: find.byIcon(Icons.chevron_right_rounded), matching: find.byType(IconButton))).onPressed, isNull);

    await tester.tap(_previousArrow);
    await tester.pumpAndSettle();
    expect(_detail('team-1'), findsOneWidget);
    expect(find.text('Luis Gómez'), findsOneWidget);
  });

  testWidgets('deslizar el carrusel elige el equipo vecino, y se puede volver deslizando', (tester) async {
    await _openTeamsPage(tester, _FakePlayersService());

    // Más de media página (800 / 2) más la holgura táctil que el arrastre de la prueba descuenta.
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(_detail('team-2'), findsOneWidget);
    expect(find.text('Eva Gómez'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(_detail('team-1'), findsOneWidget);
    expect(find.text('Luis Gómez'), findsOneWidget);
  });

  testWidgets('el equipo elegido pasa a ser el activo de toda la app y se guarda en el dispositivo', (tester) async {
    await _openTeamsPage(tester, _FakePlayersService());
    final activeTeam = getIt<ActiveTeamNotifier>();
    expect(activeTeam.activeTeamId, 'team-1');

    await _goToNextTeam(tester);

    expect(activeTeam.activeTeamId, 'team-2');
    expect((await SharedPreferences.getInstance()).getString('active_team_id'), 'team-2');
  });

  testWidgets('al volver a abrir la pantalla se ve el equipo que se había elegido', (tester) async {
    SharedPreferences.setMockInitialValues({'active_team_id': 'team-2'});

    await _openTeamsPage(tester, _FakePlayersService());

    expect(_detail('team-2'), findsOneWidget);
    expect(find.text('Eva Gómez'), findsOneWidget);
  });

  testWidgets('un equipo guardado que ya no es suyo se ignora: se ve el último al que entró', (tester) async {
    SharedPreferences.setMockInitialValues({'active_team_id': 'team-que-dejo'});

    await _openTeamsPage(tester, _FakePlayersService());

    expect(_detail('team-1'), findsOneWidget);
  });

  testWidgets('cada tarjeta marca con una estrella si el jugador es capitán de ese equipo', (tester) async {
    await _openTeamsPage(tester, _FakePlayersService());
    final captainStar = find.byIcon(Icons.star_rounded);

    expect(find.descendant(of: _card('team-1'), matching: captainStar), findsOneWidget);
    expect(find.descendant(of: _card('team-1'), matching: find.text('2 jugadores · Capitán')), findsOneWidget);

    await _goToNextTeam(tester);

    expect(find.descendant(of: _card('team-2'), matching: captainStar), findsNothing);
    expect(find.descendant(of: _card('team-2'), matching: find.text('2 jugadores')), findsOneWidget);
  });

  testWidgets('un lector de pantalla lee la tarjeta con su equipo y dice que está elegida', (tester) async {
    final semantics = tester.ensureSemantics();
    await _openTeamsPage(tester, _FakePlayersService());

    final selected = tester.getSemantics(_card('team-1'));
    expect(selected.label, allOf(contains('Los Tigres'), contains('Capitán')));
    expect(selected.flagsCollection.isSelected, Tristate.isTrue);
    semantics.dispose();
  });

  testWidgets('en el detalle de cada equipo su capitán va primero', (tester) async {
    await _openTeamsPage(tester, _FakePlayersService());
    await _goToNextTeam(tester);

    // En Los Pumas la capitana es Eva, y va antes que Ana.
    expect(tester.getTopLeft(find.text('Eva Gómez')).dy, lessThan(tester.getTopLeft(find.text('Ana Gómez')).dy));
  });

  testWidgets('con un solo equipo no hay nada que elegir: su tarjeta y su detalle', (tester) async {
    await _openTeamsPage(tester, _FakePlayersService(teams: const [PlayerTeam(teamId: 'team-1', teamName: 'Los Tigres')]));

    expect(find.text('Tu equipo'), findsOneWidget);
    expect(find.textContaining('Tus equipos'), findsNothing);
    expect(find.textContaining('La app muestra la información'), findsNothing);
    expect(find.byType(PageView), findsNothing);
    expect(_nextArrow, findsNothing);
    expect(find.text('Los Tigres'), findsOneWidget);
    expect(find.text('Luis Gómez'), findsOneWidget);
  });

  testWidgets('un equipo que ya no existe se omite y los demás se ven', (tester) async {
    await _openTeamsPage(
      tester,
      _FakePlayersService(
        teams: const [
          PlayerTeam(teamId: 'team-3', teamName: 'Los Fantasmas'),
          PlayerTeam(teamId: 'team-2', teamName: 'Los Pumas'),
        ],
      ),
    );

    expect(find.text('Los Fantasmas'), findsNothing);
    expect(_detail('team-2'), findsOneWidget);
    // Y el equipo activo de la app es uno que sí se ve.
    expect(getIt<ActiveTeamNotifier>().activeTeamId, 'team-2');
    expect(find.text('Aún no tienes un equipo'), findsNothing);
  });

  testWidgets('abandonar saca solo del equipo elegido, y la pantalla sigue con el otro', (tester) async {
    final players = _FakePlayersService();
    await _openTeamsPage(tester, players);
    await _goToNextTeam(tester);

    await _tapLeaveButton(tester);
    expect(find.text('¿Abandonar Los Pumas?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Abandonar'));
    await _settleAfterReload(tester);

    expect(players.left, [(playerId: 'ana', teamId: 'team-2')]);
    // No queda como quien no tiene equipo: le queda Los Tigres, ya sin carrusel, y pasa a ser el activo.
    expect(find.text('Aún no tienes un equipo'), findsNothing);
    expect(_detail('team-1'), findsOneWidget);
    expect(find.text('Los Pumas'), findsNothing);
    expect(find.byType(PageView), findsNothing);
    expect(getIt<ActiveTeamNotifier>().activeTeamId, 'team-1');
  });

  testWidgets('el aviso de la capitanía depende del equipo que se abandona', (tester) async {
    await _openTeamsPage(tester, _FakePlayersService());

    // Capitana de Los Tigres: lo avisa.
    await _tapLeaveButton(tester);
    expect(find.textContaining('También dejarás de ser el capitán.'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    // Jugadora de Los Pumas: no.
    await _goToNextTeam(tester);
    await _tapLeaveButton(tester);
    expect(find.textContaining('También dejarás de ser el capitán.'), findsNothing);
  });

  testWidgets('si abandona el último equipo que le quedaba, la pantalla queda como la de quien no tiene equipo', (tester) async {
    final players = _FakePlayersService(teams: const [PlayerTeam(teamId: 'team-1', teamName: 'Los Tigres', isCaptain: true)]);
    await _openTeamsPage(tester, players);

    await _tapLeaveButton(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Abandonar'));
    await _settleAfterReload(tester);

    expect(players.left, [(playerId: 'ana', teamId: 'team-1')]);
    expect(find.text('Aún no tienes un equipo'), findsOneWidget);
    expect(getIt<ActiveTeamNotifier>().activeTeamId, isNull);
  });
}
