import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';

/// El capitán va primero; los demás conservan el orden en que los manda el backend.
List<PlayerModel> sortCaptainFirst(List<PlayerModel> members) => [
      ...members.where((member) => member.isCaptain),
      ...members.where((member) => !member.isCaptain),
    ];

/// El equipo que se ve tras leer los del jugador ([teamIds], del último al que entró al más antiguo; no puede ir vacía):
/// el que ya veía si sigue siendo suyo; si lo abandonó, el que ocupa ahora su lugar (o el último de la lista); y al abrir
/// la pantalla, el primero, que es el último al que entró.
String pickSelectedTeamId(List<String> teamIds, {String? previousId, int previousIndex = 0}) {
  if (previousId != null && teamIds.contains(previousId)) return previousId;
  return teamIds[previousIndex.clamp(0, teamIds.length - 1)];
}
