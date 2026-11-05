import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/rankings/data/models/player_stats_model.dart';
import 'package:sport_platform/modules/rankings/domain/my_stats.dart';

void main() {
  const stats = [
    PlayerStatsModel(playerId: 'ana', teamId: 't1', goals: 5, assists: 2),
    PlayerStatsModel(playerId: 'luis', teamId: 't1', goals: 1, redCards: 1),
  ];

  test('encuentra lo del propio jugador por su id', () {
    final mine = findPlayerStats(stats, 'luis');

    expect(mine?.goals, 1);
    expect(mine?.redCards, 1);
  });

  test('un jugador sin eventos de partido no tiene estadísticas', () {
    expect(findPlayerStats(stats, 'nadie'), isNull);
  });

  test('sin jugador (la cuenta aún no tiene) no hay nada que buscar', () {
    expect(findPlayerStats(stats, null), isNull);
    expect(findPlayerStats(stats, ''), isNull);
    expect(findPlayerStats(const [], 'ana'), isNull);
  });
}
