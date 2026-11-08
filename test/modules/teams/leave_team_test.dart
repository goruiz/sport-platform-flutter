import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/teams_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/team_model.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/teams/presentation/pages/teams_page.dart';

import '../../support/real_translations.dart';

const _team = TeamModel(id: 'team-1', name: 'Los Tigres');

PlayerModel _player({bool isCaptain = false, String? teamId = 'team-1'}) => PlayerModel(
  id: 'ana',
  firstName: 'Ana',
  lastName: 'Pérez',
  email: 'ana@email.com',
  teamId: teamId,
  teamName: teamId == null ? null : _team.name,
  isCaptain: isCaptain,
);

/// El backend de mentira: el jugador tiene equipo hasta que lo abandona.
class _FakePlayersService extends PlayersService {
  final bool isCaptain;
  final bool failsToLeave;
  final List<String> leftPlayerIds = [];

  _FakePlayersService({this.isCaptain = false, this.failsToLeave = false});

  bool get hasLeft => leftPlayerIds.isNotEmpty;

  @override
  Future<PlayerModel?> getCurrent() async => _player(isCaptain: isCaptain, teamId: hasLeft ? null : 'team-1');

  @override
  Future<List<PlayerModel>> getByTeamId(String teamId) async => [_player(isCaptain: isCaptain)];

  @override
  Future<PlayerModel> removeFromTeam(String playerId) async {
    if (failsToLeave) throw Exception('sin red');
    leftPlayerIds.add(playerId);
    return _player(teamId: null);
  }
}

class _FakeTeamsService extends TeamsService {
  @override
  Future<TeamModel?> getById(String id) async => _team;
}

const _menuItem = MenuItemModel(id: 'menu-teams', name: 'Equipo');

Future<void> _openTeamsPage(WidgetTester tester, _FakePlayersService players) async {
  getIt.registerSingleton<PlayersService>(players);
  getIt.registerSingleton<TeamsService>(_FakeTeamsService());
  await pumpWithRealTranslations(tester, home: (_) => const TeamsPage(item: _menuItem));
  await tester.pumpAndSettle();
}

Future<void> _tapLeaveButton(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(OutlinedButton, 'Abandonar equipo'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(initRealTranslations);
  tearDown(getIt.reset);

  testWidgets('el jugador con equipo ve la acción de abandonarlo al final de la pantalla', (tester) async {
    await _openTeamsPage(tester, _FakePlayersService());

    expect(find.text('Los Tigres'), findsWidgets);
    expect(find.widgetWithText(OutlinedButton, 'Abandonar equipo'), findsOneWidget);
  });

  testWidgets('pide confirmación con el nombre del equipo y, si cancela, no lo abandona', (tester) async {
    final players = _FakePlayersService();
    await _openTeamsPage(tester, players);

    await _tapLeaveButton(tester);

    expect(find.text('¿Abandonar Los Tigres?'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(players.leftPlayerIds, isEmpty);
    expect(find.text('¿Abandonar Los Tigres?'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Abandonar equipo'), findsOneWidget);
  });

  testWidgets('al confirmar sale del equipo, avisa y la pantalla queda como la de quien no tiene equipo', (tester) async {
    final players = _FakePlayersService();
    await _openTeamsPage(tester, players);

    await _tapLeaveButton(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Abandonar'));
    await tester.pumpAndSettle();

    expect(players.leftPlayerIds, ['ana']);
    expect(find.text('Saliste del equipo.'), findsOneWidget);
    expect(find.text('Aún no tienes un equipo'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Abandonar equipo'), findsNothing);
  });

  testWidgets('al capitán se le avisa que también pierde la capitanía', (tester) async {
    await _openTeamsPage(tester, _FakePlayersService(isCaptain: true));

    await _tapLeaveButton(tester);

    expect(find.textContaining('También dejarás de ser el capitán.'), findsOneWidget);
  });

  testWidgets('quien no es capitán no ve ese aviso', (tester) async {
    await _openTeamsPage(tester, _FakePlayersService());

    await _tapLeaveButton(tester);

    expect(find.textContaining('También dejarás de ser el capitán.'), findsNothing);
  });

  testWidgets('si falla, avisa y el jugador sigue en su equipo', (tester) async {
    final players = _FakePlayersService(failsToLeave: true);
    await _openTeamsPage(tester, players);

    await _tapLeaveButton(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Abandonar'));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo abandonar el equipo. Inténtalo de nuevo.'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Abandonar equipo'), findsOneWidget);
    expect(find.text('Aún no tienes un equipo'), findsNothing);
  });
}
