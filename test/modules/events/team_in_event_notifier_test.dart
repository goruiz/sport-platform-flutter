import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/providers/team_in_event_notifier.dart';
import 'package:sport_platform/modules/matches/data/datasource/matches_service.dart';
import 'package:sport_platform/modules/rankings/data/datasource/player_stats_service.dart';
import 'package:sport_platform/modules/rankings/data/models/player_stats_model.dart';
import 'package:sport_platform/shared/enums/summary_status.dart';

import '../../support/builders.dart';

class _FakeMatchesService extends MatchesService {
  final Future<List<MatchModel>> Function() onRead;

  _FakeMatchesService(this.onRead);

  @override
  Future<List<MatchModel>> getByEvent(String eventId) => onRead();
}

class _FakePlayerStatsService extends PlayerStatsService {
  final Future<List<PlayerStatsModel>> Function() onRead;

  _FakePlayerStatsService(this.onRead);

  @override
  Future<List<PlayerStatsModel>> getByEvent(String eventId) => onRead();
}

class _FakePlayersService extends PlayersService {
  final Future<List<PlayerModel>> Function() onRead;
  String? requestedTeamId;

  _FakePlayersService(this.onRead);

  @override
  Future<List<PlayerModel>> getByTeamId(String teamId) {
    requestedTeamId = teamId;
    return onRead();
  }
}

TeamInEventNotifier _notifier({
  Future<List<MatchModel>> Function()? matches,
  Future<List<PlayerStatsModel>> Function()? stats,
  Future<List<PlayerModel>> Function()? roster,
  _FakePlayersService? playersService,
}) {
  return TeamInEventNotifier(
    matchesService: _FakeMatchesService(matches ?? () async => const []),
    playerStatsService: _FakePlayerStatsService(stats ?? () async => const []),
    playersService: playersService ?? _FakePlayersService(roster ?? () async => const []),
    eventId: 'e1',
    teamId: 't1',
  );
}

const _ana = PlayerModel(id: 'ana', firstName: 'Ana', lastName: 'Pérez', email: 'ana@email.com', teamId: 't1');

void main() {
  test('al cargar lee los partidos y estadísticas del evento y la plantilla del equipo', () async {
    final playersService = _FakePlayersService(() async => [_ana]);
    final notifier = _notifier(
      matches: () async => [matchOf(id: 'm1', homeTeamId: 't1', date: DateTime(2026, 11, 1))],
      stats: () async => [const PlayerStatsModel(playerId: 'ana', teamId: 't1', goals: 2)],
      playersService: playersService,
    );

    await notifier.load();

    expect(notifier.matchesStatus, SummaryStatus.ready);
    expect(notifier.eventMatches, hasLength(1));
    expect(notifier.statsStatus, SummaryStatus.ready);
    expect(notifier.eventStats.single.goals, 2);
    expect(notifier.rosterStatus, SummaryStatus.ready);
    expect(notifier.roster.single.id, 'ana');
    expect(playersService.requestedTeamId, 't1');
  });

  test('una plantilla que el backend no deja ver no es un error: queda vacía', () async {
    final notifier = _notifier(roster: () => Future.error(Exception('403')));

    await notifier.load();

    expect(notifier.rosterStatus, SummaryStatus.ready);
    expect(notifier.roster, isEmpty);
  });

  test('si fallan los partidos, las estadísticas se siguen viendo', () async {
    final notifier = _notifier(
      matches: () => Future.error(Exception('sin red')),
      stats: () async => [const PlayerStatsModel(playerId: 'ana', teamId: 't1', goals: 1)],
    );

    await notifier.load();

    expect(notifier.matchesStatus, SummaryStatus.failed);
    expect(notifier.statsStatus, SummaryStatus.ready);
  });

  test('un fallo se puede reintentar sin tocar lo demás', () async {
    var fail = true;
    final notifier = _notifier(
      stats: () => fail ? Future.error(Exception('sin red')) : Future.value(const [PlayerStatsModel(playerId: 'ana', teamId: 't1')]),
    );
    await notifier.load();
    expect(notifier.statsStatus, SummaryStatus.failed);

    fail = false;
    await notifier.loadStats();

    expect(notifier.statsStatus, SummaryStatus.ready);
    expect(notifier.eventStats, hasLength(1));
    expect(notifier.matchesStatus, SummaryStatus.ready);
  });
}
