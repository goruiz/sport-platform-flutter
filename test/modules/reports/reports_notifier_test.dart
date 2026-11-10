import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/matches/data/datasource/matches_service.dart';
import 'package:sport_platform/modules/rankings/data/datasource/player_stats_service.dart';
import 'package:sport_platform/modules/rankings/data/models/player_stats_model.dart';
import 'package:sport_platform/modules/reports/presentation/providers/reports_notifier.dart';
import 'package:sport_platform/modules/teams/presentation/providers/active_team_notifier.dart';
import 'package:sport_platform/shared/enums/summary_status.dart';

import '../../support/builders.dart';

class _FakePlayersService extends PlayersService {
  final PlayerModel? player;
  int reads = 0;

  _FakePlayersService(this.player);

  @override
  Future<PlayerModel?> getCurrent() async {
    reads++;
    return player;
  }
}

class _FakeMatchesService extends MatchesService {
  final List<MatchModel> matches;

  _FakeMatchesService(this.matches);

  @override
  Future<List<MatchModel>> getMine() async => matches;
}

class _FakePlayerStatsService extends PlayerStatsService {
  final Future<List<PlayerStatsModel>> Function(String eventId) onRead;
  final List<String> requestedEvents = [];

  _FakePlayerStatsService(this.onRead);

  @override
  Future<List<PlayerStatsModel>> getByEvent(String eventId) {
    requestedEvents.add(eventId);
    return onRead(eventId);
  }
}

const _ana = PlayerModel(
  id: 'ana',
  firstName: 'Ana',
  lastName: 'Pérez',
  email: 'ana@email.com',
  teamId: 'mine',
  teamName: 'Tigres',
);

PlayerStatsModel _stats(String playerId, String teamId, {int yellow = 0, int red = 0, int fouls = 0}) =>
    PlayerStatsModel(playerId: playerId, teamId: teamId, yellowCards: yellow, redCards: red, fouls: fouls);

ReportsNotifier _notifier({
  PlayerModel? player = _ana,
  List<MatchModel>? matches,
  Future<List<PlayerStatsModel>> Function(String eventId)? stats,
  _FakePlayerStatsService? statsService,
  _FakePlayersService? playersService,
  ActiveTeamNotifier? activeTeam,
}) {
  return ReportsNotifier(
    playersService: playersService ?? _FakePlayersService(player),
    activeTeam: activeTeam ?? ActiveTeamNotifier(),
    matchesService: _FakeMatchesService(
      matches ??
          [
            matchOf(id: 'a', homeTeamId: 'mine', date: DateTime(2026, 10, 1), homeScore: 2, awayScore: 0, eventId: 'e1'),
            matchOf(id: 'b', awayTeamId: 'mine', date: DateTime(2026, 10, 8), homeScore: 1, awayScore: 1, eventId: 'e2'),
            matchOf(id: 'c', homeTeamId: 'mine', date: DateTime(2026, 10, 15), eventId: 'e2'),
          ],
    ),
    playerStatsService: statsService ?? _FakePlayerStatsService(stats ?? (_) async => const []),
  );
}

const _anaInThreeTeams = PlayerModel(
  id: 'ana',
  firstName: 'Ana',
  lastName: 'Pérez',
  email: 'ana@email.com',
  teamId: 'mine',
  teamName: 'Tigres',
  teams: [
    PlayerTeam(teamId: 'mine', teamName: 'Tigres'),
    PlayerTeam(teamId: 'other', teamName: 'Pumas'),
    PlayerTeam(teamId: 'third', teamName: 'Osos'),
  ],
);

const _anaInTwoTeams = PlayerModel(
  id: 'ana',
  firstName: 'Ana',
  lastName: 'Pérez',
  email: 'ana@email.com',
  teamId: 'mine',
  teamName: 'Tigres',
  teams: [
    PlayerTeam(teamId: 'mine', teamName: 'Tigres'),
    PlayerTeam(teamId: 'other', teamName: 'Pumas'),
  ],
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('cuenta en cuántos eventos juega el equipo, aunque algún partido aún no tenga resultado', () async {
    final notifier = _notifier();

    await notifier.load();

    expect(notifier.eventsPlayed, 2);
    expect(notifier.record.played, 2);
  });

  group('un jugador de varios equipos (uno por organización)', () {
    // `getMine` trae los partidos de todos sus equipos.
    final bothTeamsMatches = [
      matchOf(id: 'a', homeTeamId: 'mine', date: DateTime(2026, 10, 1), homeScore: 2, awayScore: 0, eventId: 'e1'),
      matchOf(id: 'b', homeTeamId: 'other', date: DateTime(2026, 10, 2), homeScore: 0, awayScore: 3, eventId: 'e9'),
    ];

    test('el reporte es del primer equipo (el último al que entró) y no mezcla los partidos del otro', () async {
      final activeTeam = ActiveTeamNotifier();
      final notifier = _notifier(player: _anaInTwoTeams, matches: bothTeamsMatches, activeTeam: activeTeam);

      await notifier.load();

      expect(activeTeam.teams.map((team) => team.teamId), ['mine', 'other']);
      expect(notifier.selectedTeamId, 'mine');
      expect(notifier.teamName, 'Tigres');
      expect(notifier.record.won, 1);
      expect(notifier.record.played, 1);
      // El evento del otro equipo no cuenta como evento en que juega este.
      expect(notifier.eventsPlayed, 1);
    });

    test('al elegir el otro equipo en la app el reporte pasa a ser el suyo', () async {
      final activeTeam = ActiveTeamNotifier();
      final notifier = _notifier(player: _anaInTwoTeams, matches: bothTeamsMatches, activeTeam: activeTeam);
      await notifier.load();

      activeTeam.select('other');
      await pumpEventQueue();

      expect(notifier.selectedTeamId, 'other');
      expect(notifier.teamName, 'Pumas');
      expect(notifier.record.lost, 1);
      expect(notifier.record.won, 0);
      expect(notifier.eventsPlayed, 1);
    });

    test('refrescar conserva el equipo elegido', () async {
      final activeTeam = ActiveTeamNotifier();
      final notifier = _notifier(player: _anaInTwoTeams, matches: bothTeamsMatches, activeTeam: activeTeam);
      await notifier.load();
      activeTeam.select('other');
      await pumpEventQueue();

      await notifier.load();

      expect(notifier.selectedTeamId, 'other');
    });

    test('solo se vuelve a leer cuando cambia el equipo activo, no por otros avisos', () async {
      final activeTeam = ActiveTeamNotifier();
      final players = _FakePlayersService(_anaInTwoTeams);
      final notifier = _notifier(playersService: players, matches: bothTeamsMatches, activeTeam: activeTeam);
      await notifier.load();
      expect(players.reads, 1);

      // Un tercer equipo aparece en la lista, pero el activo sigue siendo el mismo: nada se recarga.
      await activeTeam.sync(_anaInThreeTeams);
      await pumpEventQueue();
      expect(players.reads, 1);

      activeTeam.select('other');
      await pumpEventQueue();
      expect(players.reads, 2);
    });
  });

  test('suma las tarjetas y faltas de los jugadores del equipo en cada evento', () async {
    final statsService = _FakePlayerStatsService((eventId) async {
      return switch (eventId) {
        'e1' => [_stats('p1', 'mine', yellow: 2, fouls: 3), _stats('rival', 'other', yellow: 9)],
        _ => [_stats('p2', 'mine', yellow: 1, red: 1, fouls: 2)],
      };
    });
    final notifier = _notifier(statsService: statsService);

    await notifier.load();

    expect(statsService.requestedEvents, unorderedEquals(['e1', 'e2']));
    expect(notifier.disciplineStatus, SummaryStatus.ready);
    expect(notifier.discipline.yellowCards, 3);
    expect(notifier.discipline.redCards, 1);
    expect(notifier.discipline.fouls, 5);
  });

  test('si fallan las estadísticas, el reporte se ve y solo ese bloque falla', () async {
    final notifier = _notifier(stats: (_) => Future.error(Exception('sin red')));

    await notifier.load();

    expect(notifier.error, isNull);
    expect(notifier.loading, isFalse);
    expect(notifier.record.played, 2);
    expect(notifier.disciplineStatus, SummaryStatus.failed);
  });

  test('el reporte se muestra antes de que lleguen las estadísticas', () async {
    final notifier = _notifier();
    final loading = <bool>[];
    final disciplineStatuses = <SummaryStatus>[];
    notifier.addListener(() {
      loading.add(notifier.loading);
      disciplineStatuses.add(notifier.disciplineStatus);
    });

    await notifier.load();

    // En algún momento el reporte ya estaba cargado mientras la disciplina aún se leía.
    final index = loading.indexOf(false);
    expect(disciplineStatuses[index], SummaryStatus.loading);
    expect(disciplineStatuses.last, SummaryStatus.ready);
  });

  test('sin equipo no hay reporte ni se piden estadísticas', () async {
    final statsService = _FakePlayerStatsService((_) async => const []);
    final notifier = _notifier(
      player: const PlayerModel(id: 'ana', firstName: 'Ana', lastName: 'Pérez', email: 'ana@email.com'),
      statsService: statsService,
    );

    await notifier.load();

    expect(notifier.hasTeam, isFalse);
    expect(notifier.eventsPlayed, 0);
    expect(statsService.requestedEvents, isEmpty);
  });

  test('un fallo al leer los partidos es un error del reporte y no pide estadísticas', () async {
    final statsService = _FakePlayerStatsService((_) async => const []);
    final notifier = ReportsNotifier(
      playersService: _FakePlayersService(_ana),
      matchesService: _ThrowingMatchesService(),
      playerStatsService: statsService,
      activeTeam: ActiveTeamNotifier(),
    );

    await notifier.load();

    expect(notifier.error, 'reports.load_error');
    expect(statsService.requestedEvents, isEmpty);
  });
}

class _ThrowingMatchesService extends MatchesService {
  @override
  Future<List<MatchModel>> getMine() => Future.error(Exception('sin red'));
}
