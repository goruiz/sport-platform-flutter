import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/matches/data/models/match_event_model.dart';
import 'package:sport_platform/modules/matches/domain/enums/match_event_type.dart';
import 'package:sport_platform/modules/rankings/data/models/player_stats_model.dart';

void main() {
  group('MatchEventModel.fromJson', () {
    test('lee un gol con su jugador y su minuto', () {
      final event = MatchEventModel.fromJson({
        'id': 'e1',
        'matchId': 'm1',
        'playerId': 'p1',
        'playerName': 'Ana Lopez',
        'teamId': 't1',
        'eventType': 'GOAL',
        'minute': 23,
      });

      expect(event.type, MatchEventType.goal);
      expect(event.minute, 23);
      expect(event.playerName, 'Ana Lopez');
    });

    test('un tipo que la app no conoce queda sin tipo en vez de romper', () {
      final event = MatchEventModel.fromJson({
        'id': 'e1',
        'eventType': 'PENALTY_SHOOTOUT',
      });

      expect(event.type, isNull);
    });

    test('un evento sin minuto ni jugador (borrado) se lee igual', () {
      final event = MatchEventModel.fromJson({
        'id': 'e1',
        'eventType': 'FOUL',
        'minute': null,
      });

      expect(event.minute, isNull);
      expect(event.playerName, isNull);
    });
  });

  test('cada tipo se reconoce por el valor del backend', () {
    for (final type in MatchEventType.values) {
      expect(MatchEventType.fromApi(type.apiValue), type);
    }
    expect(MatchEventType.fromApi(null), isNull);
  });

  group('PlayerStatsModel.fromJson', () {
    test('lee los contadores y suma las tarjetas', () {
      final stats = PlayerStatsModel.fromJson({
        'playerId': 'p1',
        'playerName': 'Ana Lopez',
        'teamId': 't1',
        'teamName': 'Tigres',
        'goals': 4,
        'assists': 2,
        'yellowCards': 1,
        'redCards': 1,
        'fouls': 3,
      });

      expect(stats.goals, 4);
      expect(stats.cards, 2);
      expect(stats.fouls, 3);
    });

    test('un contador ausente vale cero', () {
      final stats = PlayerStatsModel.fromJson({
        'playerId': 'p1',
        'teamId': 't1',
      });

      expect(stats.goals, 0);
      expect(stats.cards, 0);
    });
  });
}
