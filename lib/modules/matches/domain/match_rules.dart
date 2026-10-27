import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/enums/match_status.dart';

/// Reglas de los partidos que usan varias pantallas. Funciones puras: el reloj entra por parámetro.

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
