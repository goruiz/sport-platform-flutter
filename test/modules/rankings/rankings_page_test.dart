import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/standings_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/standing_model.dart';
import 'package:sport_platform/modules/events/shared/data/datasource/events_search_service.dart';
import 'package:sport_platform/modules/events/shared/data/datasource/team_events_service.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/rankings/data/datasource/player_stats_service.dart';
import 'package:sport_platform/modules/rankings/data/models/player_stats_model.dart';
import 'package:sport_platform/modules/rankings/presentation/pages/rankings_page.dart';
import 'package:sport_platform/modules/teams/presentation/providers/active_team_notifier.dart';

import '../../support/builders.dart';
import '../../support/real_translations.dart';

class _FakeEventsSearchService extends EventsSearchService {
  @override
  Future<EventsPage> search({text, status, int page = 0, int? size}) async => EventsPage(
    events: [eventOf(startDate: DateTime(2026, 1, 1), endDate: DateTime(2026, 12, 1))],
    page: 0,
    totalPages: 1,
    totalElements: 1,
  );
}

/// Los eventos en que juega cada equipo; un equipo que no está en el mapa no juega ninguno.
class _FakeTeamEventsService extends TeamEventsService {
  final Map<String, List<EventModel>> eventsByTeam;

  _FakeTeamEventsService(this.eventsByTeam);

  @override
  Future<List<EventModel>> getOfTeam(String teamId) async => eventsByTeam[teamId] ?? const [];
}

class _FakeStandingsService extends StandingsService {
  @override
  Future<List<StandingModel>> getById(String id) async => const [];
}

class _FakePlayersService extends PlayersService {
  final PlayerModel? current;

  _FakePlayersService(this.current);

  @override
  Future<PlayerModel?> getCurrent() async => current;
}

class _FakePlayerStatsService extends PlayerStatsService {
  final List<PlayerStatsModel> stats;

  _FakePlayerStatsService(this.stats);

  @override
  Future<List<PlayerStatsModel>> getByEvent(String eventId) async => stats;
}

const _myTeamId = 'mi-equipo';

PlayerModel _me({String? teamId = _myTeamId}) =>
    PlayerModel(id: 'ana', firstName: 'Ana', lastName: 'Pérez', email: 'ana@email.com', teamId: teamId);

const _allStats = [
  PlayerStatsModel(playerId: 'ana', playerName: 'Ana Pérez', teamId: _myTeamId, teamName: 'Tigres', goals: 3),
  PlayerStatsModel(playerId: 'luis', playerName: 'Luis Soto', teamId: _myTeamId, teamName: 'Tigres', goals: 1),
  PlayerStatsModel(playerId: 'eva', playerName: 'Eva Ruiz', teamId: 'rival', teamName: 'Leones', goals: 5),
];

const _otherTeamId = 'otro-equipo';

const _menuItem = MenuItemModel(id: 'menu-rankings', name: 'Rankings');

EventModel _event(String id, String name) =>
    eventOf(id: id, name: name, startDate: DateTime(2026, 1, 1), endDate: DateTime(2026, 12, 1));

/// Un jugador que juega en dos equipos: Tigres (el primero, el activo al abrir) y Pumas.
const _inTwoTeams = PlayerModel(
  id: 'ana',
  firstName: 'Ana',
  lastName: 'Pérez',
  email: 'ana@email.com',
  teamId: _myTeamId,
  teams: [
    PlayerTeam(teamId: _myTeamId, teamName: 'Tigres'),
    PlayerTeam(teamId: _otherTeamId, teamName: 'Pumas'),
  ],
);

Future<void> _openScorers(
  WidgetTester tester, {
  required PlayerModel? player,
  List<PlayerStatsModel> stats = _allStats,
  ActiveTeamNotifier? activeTeam,
  Map<String, List<EventModel>>? eventsByTeam,
}) async {
  final sharedEvent = eventOf(startDate: DateTime(2026, 1, 1), endDate: DateTime(2026, 12, 1));
  getIt.registerSingleton<TeamEventsService>(
    _FakeTeamEventsService(eventsByTeam ?? {_myTeamId: [sharedEvent], _otherTeamId: [sharedEvent]}),
  );
  getIt.registerSingleton<EventsSearchService>(_FakeEventsSearchService());
  getIt.registerSingleton<StandingsService>(_FakeStandingsService());
  getIt.registerSingleton<PlayersService>(_FakePlayersService(player));
  getIt.registerSingleton<PlayerStatsService>(_FakePlayerStatsService(stats));
  getIt.registerSingleton<ActiveTeamNotifier>(activeTeam ?? ActiveTeamNotifier());
  await pumpWithRealTranslations(tester, home: (_) => const RankingsPage(item: _menuItem));
  await _pumpFrames(tester);
  await tester.tap(find.text('Goleadores'));
  await _pumpFrames(tester);
}

/// Avanza la pantalla alternando fotogramas con turnos del bucle real. Las lecturas de la página nacen en `initState`,
/// que `pumpWithRealTranslations` ejecuta en la zona de tiempo real: quien las espera después (la pestaña que se monta
/// al tocarla) solo se entera cuando ese bucle corre, y `pumpAndSettle` no se lo da.
Future<void> _pumpFrames(WidgetTester tester, {int frames = 10}) async {
  for (var i = 0; i < frames; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(initRealTranslations);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(getIt.reset);

  testWidgets('quien tiene equipo ve el selector y, por defecto, a todos los jugadores del evento', (tester) async {
    await _openScorers(tester, player: _me());

    expect(find.text('Todo el evento'), findsOneWidget);
    expect(find.text('Mi equipo'), findsOneWidget);
    expect(find.text('Eva Ruiz'), findsOneWidget);
    expect(find.text('Luis Soto'), findsOneWidget);
  });

  testWidgets('«Mi equipo» deja solo a los compañeros', (tester) async {
    await _openScorers(tester, player: _me());

    await tester.tap(find.text('Mi equipo'));
    await _pumpFrames(tester);

    expect(find.text('Eva Ruiz'), findsNothing);
    expect(find.text('Luis Soto'), findsOneWidget);
    expect(find.textContaining('Ana Pérez'), findsWidgets);
  });

  testWidgets('el jugador de la cuenta se reconoce en la lista con «(Tú)»', (tester) async {
    await _openScorers(tester, player: _me());

    expect(find.text('Ana Pérez (Tú)'), findsOneWidget);
    expect(find.text('Luis Soto (Tú)'), findsNothing);
  });

  testWidgets('si su equipo aún no tiene datos, «Mi equipo» lo explica en vez de mostrar otros jugadores', (tester) async {
    await _openScorers(
      tester,
      player: _me(),
      stats: const [PlayerStatsModel(playerId: 'eva', playerName: 'Eva Ruiz', teamId: 'rival', goals: 5)],
    );

    await tester.tap(find.text('Mi equipo'));
    await _pumpFrames(tester);

    expect(find.text('Eva Ruiz'), findsNothing);
    expect(find.text('Los jugadores de tu equipo aparecerán cuando se registren goles y tarjetas.'), findsOneWidget);
  });

  testWidgets('«Mi equipo» abarca solo al equipo activo y sigue a la selección de la app', (tester) async {
    final activeTeam = ActiveTeamNotifier();
    await _openScorers(
      tester,
      player: _inTwoTeams,
      activeTeam: activeTeam,
      stats: const [
        ..._allStats,
        PlayerStatsModel(playerId: 'ivo', playerName: 'Ivo Paz', teamId: _otherTeamId, teamName: 'Pumas', goals: 2),
      ],
    );

    await tester.tap(find.text('Mi equipo'));
    await _pumpFrames(tester);
    expect(find.text('Luis Soto'), findsOneWidget);
    expect(find.text('Ivo Paz'), findsNothing);

    activeTeam.select(_otherTeamId);
    await _pumpFrames(tester);
    expect(find.text('Ivo Paz'), findsOneWidget);
    expect(find.text('Luis Soto'), findsNothing);
  });

  group('los eventos que se ofrecen son los del equipo activo', () {
    final eventsByTeam = {
      _myTeamId: [_event('liga', 'Liga'), _event('apertura', 'Apertura')],
      _otherTeamId: [_event('copa', 'Copa')],
    };

    List<String> offeredEventIds(WidgetTester tester) => tester
        .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
        .items!
        .map((item) => item.value!)
        .toList();

    testWidgets('abre con los eventos del equipo activo, no con todos los que ve el jugador', (tester) async {
      await _openScorers(tester, player: _inTwoTeams, eventsByTeam: eventsByTeam);

      expect(offeredEventIds(tester), ['liga', 'apertura']);
    });

    testWidgets('al cambiar de equipo se ofrecen solo los eventos del nuevo y queda elegido uno de ellos', (tester) async {
      final activeTeam = ActiveTeamNotifier();
      await _openScorers(tester, player: _inTwoTeams, activeTeam: activeTeam, eventsByTeam: eventsByTeam);

      activeTeam.select(_otherTeamId);
      await _pumpFrames(tester);

      expect(offeredEventIds(tester), ['copa']);
      expect(tester.widget<DropdownButton<String>>(find.byType(DropdownButton<String>)).value, 'copa');
    });

    testWidgets('si el evento elegido también es del otro equipo, sigue elegido', (tester) async {
      final activeTeam = ActiveTeamNotifier();
      await _openScorers(
        tester,
        player: _inTwoTeams,
        activeTeam: activeTeam,
        eventsByTeam: {
          _myTeamId: [_event('liga', 'Liga'), _event('apertura', 'Apertura')],
          _otherTeamId: [_event('copa', 'Copa'), _event('liga', 'Liga')],
        },
      );

      activeTeam.select(_otherTeamId);
      await _pumpFrames(tester);

      expect(tester.widget<DropdownButton<String>>(find.byType(DropdownButton<String>)).value, 'liga');
    });

    testWidgets('si el equipo elegido no juega ningún evento lo dice y deja volver a cambiar de equipo', (tester) async {
      final activeTeam = ActiveTeamNotifier();
      await _openScorers(
        tester,
        player: _inTwoTeams,
        activeTeam: activeTeam,
        eventsByTeam: {_myTeamId: [_event('liga', 'Liga')]},
      );

      activeTeam.select(_otherTeamId);
      await _pumpFrames(tester);

      expect(find.text('Tu equipo aún no juega ningún evento'), findsOneWidget);
      expect(find.byType(DropdownButton<String>), findsNothing);
      expect(find.text('Liga'), findsNothing);

      // El selector de equipo sigue a la vista: sin él el jugador quedaría atrapado en un equipo sin eventos.
      expect(find.text('Pumas'), findsOneWidget);
      activeTeam.select(_myTeamId);
      await _pumpFrames(tester);
      expect(offeredEventIds(tester), ['liga']);
    });
  });

  testWidgets('quien aún no tiene equipo no ve el selector y sigue viendo el ranking del evento', (tester) async {
    await _openScorers(tester, player: _me(teamId: null));

    expect(find.byType(SegmentedButton<Object?>), findsNothing);
    expect(find.text('Mi equipo'), findsNothing);
    expect(find.text('Eva Ruiz'), findsOneWidget);
  });
}
