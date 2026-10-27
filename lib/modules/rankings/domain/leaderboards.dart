import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/event_status.dart';
import 'package:sport_platform/modules/rankings/data/models/player_stats_model.dart';

/// Los listados que se arman con las estadísticas de los jugadores de un evento.
enum LeaderboardKind {
  scorers('rankings.scorers'),
  assists('rankings.assists'),
  cards('rankings.cards');

  const LeaderboardKind(this.translationKey);

  final String translationKey;

  /// Lo que se cuenta en este listado para un jugador.
  int valueOf(PlayerStatsModel stats) => switch (this) {
        LeaderboardKind.scorers => stats.goals,
        LeaderboardKind.assists => stats.assists,
        LeaderboardKind.cards => stats.cards,
      };
}

/// Los jugadores que cuentan en el listado, de más a menos. Un jugador con cero no aparece. Ante un
/// empate gana quien tiene menos expulsiones (y, en las tarjetas, más rojas primero: son más graves).
List<PlayerStatsModel> buildLeaderboard(
  List<PlayerStatsModel> stats,
  LeaderboardKind kind,
) {
  final counted = stats.where((player) => kind.valueOf(player) > 0).toList();
  counted.sort((a, b) {
    final byValue = kind.valueOf(b).compareTo(kind.valueOf(a));
    if (byValue != 0) return byValue;
    if (kind == LeaderboardKind.cards) {
      final byReds = b.redCards.compareTo(a.redCards);
      if (byReds != 0) return byReds;
    } else {
      final byReds = a.redCards.compareTo(b.redCards);
      if (byReds != 0) return byReds;
    }
    return (a.playerName ?? '').toLowerCase().compareTo((b.playerName ?? '').toLowerCase());
  });
  return counted;
}

/// El evento con el que abre Rankings: el que está en curso más reciente; si ninguno lo está, el
/// último que empezó. Null si no hay eventos.
EventModel? pickDefaultEvent(List<EventModel> events) {
  if (events.isEmpty) return null;
  final newestFirst = [...events]..sort((a, b) => b.startDate.compareTo(a.startDate));
  for (final event in newestFirst) {
    if (event.statusType == EventStatus.active) return event;
  }
  return newestFirst.first;
}
