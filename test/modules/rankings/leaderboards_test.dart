import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/rankings/data/models/player_stats_model.dart';
import 'package:sport_platform/modules/rankings/domain/leaderboards.dart';

import '../../support/builders.dart';

PlayerStatsModel _stats(
  String name, {
  int goals = 0,
  int assists = 0,
  int yellow = 0,
  int red = 0,
}) => PlayerStatsModel(
  playerId: name,
  playerName: name,
  teamId: 't1',
  goals: goals,
  assists: assists,
  yellowCards: yellow,
  redCards: red,
);

void main() {
  group('buildLeaderboard', () {
    test(
      'los goleadores van de más a menos goles y sin los que no marcaron',
      () {
        final result = buildLeaderboard([
          _stats('Ana', goals: 1),
          _stats('Luis', goals: 3),
          _stats('Eva', assists: 2),
        ], LeaderboardKind.scorers);

        expect(result.map((player) => player.playerName), ['Luis', 'Ana']);
      },
    );

    test(
      'ante un empate de goles gana quien tiene menos tarjetas rojas, luego el nombre',
      () {
        final result = buildLeaderboard([
          _stats('Zoe', goals: 2),
          _stats('Beto', goals: 2, red: 1),
          _stats('Ana', goals: 2),
        ], LeaderboardKind.scorers);

        expect(result.map((player) => player.playerName), [
          'Ana',
          'Zoe',
          'Beto',
        ]);
      },
    );

    test('los asistentes se ordenan por asistencias', () {
      final result = buildLeaderboard([
        _stats('Ana', assists: 1),
        _stats('Luis', assists: 4),
      ], LeaderboardKind.assists);

      expect(result.first.playerName, 'Luis');
    });

    test(
      'las tarjetas suman amarillas y rojas y, ante un empate, las rojas van primero',
      () {
        final result = buildLeaderboard([
          _stats('Ana', yellow: 2),
          _stats('Luis', yellow: 1, red: 1),
          _stats('Eva', yellow: 1),
        ], LeaderboardKind.cards);

        expect(result.map((player) => player.playerName), [
          'Luis',
          'Ana',
          'Eva',
        ]);
      },
    );

    test('sin estadísticas no hay listado', () {
      expect(buildLeaderboard(const [], LeaderboardKind.scorers), isEmpty);
    });
  });

  group('pickDefaultEvent', () {
    test('sin eventos es null', () {
      expect(pickDefaultEvent(const []), isNull);
    });

    test('abre con el evento en curso más reciente', () {
      final oldActive = eventOf(
        id: 'old',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 1),
      );
      final newActive = eventOf(
        id: 'new',
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 12, 1),
      );
      final finished = eventOf(
        id: 'finished',
        status: 'FINISHED',
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 10, 1),
      );

      expect(pickDefaultEvent([oldActive, finished, newActive])?.id, 'new');
    });

    test('si ninguno está en curso abre con el último que empezó', () {
      final first = eventOf(
        id: 'first',
        status: 'FINISHED',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 6, 1),
      );
      final last = eventOf(
        id: 'last',
        status: 'UPCOMING',
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 12, 1),
      );

      expect(pickDefaultEvent([first, last])?.id, 'last');
    });
  });
}
