import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/enums/match_status.dart';

/// Reglas de los partidos que usan varias pantallas. Funciones puras: el reloj entra por parámetro.

/// Los partidos en que juega el equipo [teamId], de local o de visitante. Sin equipo no hay ninguno.
List<MatchModel> matchesOfTeam(Iterable<MatchModel> matches, String? teamId) {
  if (teamId == null || teamId.isEmpty) return const [];
  return matches
      .where((match) => match.homeTeamId == teamId || match.awayTeamId == teamId)
      .toList();
}

/// Los ids de los eventos en que juega el equipo [teamId] (los de sus partidos), sin repetir. Sin equipo no hay ninguno.
Set<String> eventIdsOfTeam(Iterable<MatchModel> matches, String? teamId) => {
      for (final match in matchesOfTeam(matches, teamId))
        if (match.eventId.isNotEmpty) match.eventId,
    };

/// Los partidos que aún no se juegan (los cancelados no cuentan), el más cercano primero.
List<MatchModel> upcomingMatches(List<MatchModel> matches, DateTime now) {
  return matches
      .where((match) =>
          match.matchDate.isAfter(now) && match.status != MatchStatus.cancelled)
      .toList()
    ..sort((a, b) => a.matchDate.compareTo(b.matchDate));
}

/// Los partidos con resultado, el más reciente primero.
List<MatchModel> playedMatches(List<MatchModel> matches) {
  return matches.where((match) => match.hasScore).toList()
    ..sort((a, b) => b.matchDate.compareTo(a.matchDate));
}

/// Todos los partidos en orden de calendario: el más antiguo primero.
List<MatchModel> matchesInCalendarOrder(List<MatchModel> matches) {
  return [...matches]..sort((a, b) => a.matchDate.compareTo(b.matchDate));
}
