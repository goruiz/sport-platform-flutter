import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/enums/match_status.dart';

/// Los partidos de un equipo en un evento, repartidos entre los que faltan y los que ya tienen resultado.
class TeamMatchesInEvent {
  /// Los que aún no tienen resultado, del más próximo al más lejano. Un partido cancelado no vuelve a jugarse: no entra.
  final List<MatchModel> upcoming;

  /// Los que ya tienen resultado, del más reciente al más antiguo.
  final List<MatchModel> results;

  const TeamMatchesInEvent({this.upcoming = const [], this.results = const []});

  bool get isEmpty => upcoming.isEmpty && results.isEmpty;
}

/// De los partidos de un evento, los que juega [teamId] repartidos entre próximos y resultados.
TeamMatchesInEvent splitTeamMatches(String teamId, Iterable<MatchModel> eventMatches) {
  final teamMatches = eventMatches
      .where((match) => match.homeTeamId == teamId || match.awayTeamId == teamId)
      .toList();
  final upcoming = teamMatches
      .where((match) => !match.hasScore && match.status != MatchStatus.cancelled)
      .toList()
    ..sort((a, b) => a.matchDate.compareTo(b.matchDate));
  final results = teamMatches.where((match) => match.hasScore).toList()
    ..sort((a, b) => b.matchDate.compareTo(a.matchDate));
  return TeamMatchesInEvent(upcoming: upcoming, results: results);
}
