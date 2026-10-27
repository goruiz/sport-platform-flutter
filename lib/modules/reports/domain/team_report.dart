import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';

/// Cómo terminó un partido para un equipo.
enum MatchResult { win, draw, loss }

/// El balance de un equipo: lo que suman sus partidos con resultado.
class TeamRecord {
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;

  const TeamRecord({
    this.won = 0,
    this.drawn = 0,
    this.lost = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
  });

  int get played => won + drawn + lost;
  int get goalDifference => goalsFor - goalsAgainst;
  bool get isEmpty => played == 0;

  /// Qué parte de los partidos jugados ganó, de 0 a 1 (0 si aún no jugó).
  double get winRate => played == 0 ? 0 : won / played;

  TeamRecord plus(
    MatchResult result, {
    required int goalsFor,
    required int goalsAgainst,
  }) => TeamRecord(
    won: won + (result == MatchResult.win ? 1 : 0),
    drawn: drawn + (result == MatchResult.draw ? 1 : 0),
    lost: lost + (result == MatchResult.loss ? 1 : 0),
    goalsFor: this.goalsFor + goalsFor,
    goalsAgainst: this.goalsAgainst + goalsAgainst,
  );
}

/// El resultado de [match] para [teamId]; null si el partido no tiene resultado o el equipo no lo jugó.
MatchResult? resultFor(String teamId, MatchModel match) {
  final home = match.homeScore;
  final away = match.awayScore;
  if (home == null || away == null) return null;
  final isHome = match.homeTeamId == teamId;
  if (!isHome && match.awayTeamId != teamId) return null;
  final own = isHome ? home : away;
  final other = isHome ? away : home;
  if (own > other) return MatchResult.win;
  if (own < other) return MatchResult.loss;
  return MatchResult.draw;
}

/// Suma los partidos con resultado de [teamId].
TeamRecord buildTeamRecord(String teamId, Iterable<MatchModel> matches) {
  var record = const TeamRecord();
  for (final match in matches) {
    final result = resultFor(teamId, match);
    if (result == null) continue;
    final isHome = match.homeTeamId == teamId;
    record = record.plus(
      result,
      goalsFor: (isHome ? match.homeScore : match.awayScore)!,
      goalsAgainst: (isHome ? match.awayScore : match.homeScore)!,
    );
  }
  return record;
}

/// El balance de [teamId] en cada evento en que jugó, por id de evento.
Map<String, TeamRecord> buildRecordsByEvent(
  String teamId,
  Iterable<MatchModel> matches,
) {
  final matchesByEvent = <String, List<MatchModel>>{};
  for (final match in matches) {
    matchesByEvent.putIfAbsent(match.eventId, () => []).add(match);
  }
  return {
    for (final entry in matchesByEvent.entries)
      entry.key: buildTeamRecord(teamId, entry.value),
  }..removeWhere((_, record) => record.isEmpty);
}

/// Los últimos [limit] resultados de [teamId], del más viejo al más reciente (como se lee una racha).
List<MatchResult> buildRecentForm(
  String teamId,
  Iterable<MatchModel> matches, {
  required int limit,
}) {
  final played =
      matches.where((match) => resultFor(teamId, match) != null).toList()
        ..sort((a, b) => a.matchDate.compareTo(b.matchDate));
  final lastOnes = played.length > limit
      ? played.sublist(played.length - limit)
      : played;
  return lastOnes.map((match) => resultFor(teamId, match)!).toList();
}
