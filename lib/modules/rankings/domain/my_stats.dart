import 'package:sport_platform/modules/rankings/data/models/player_stats_model.dart';

/// Lo que hizo el propio jugador en el evento (goles, asistencias, tarjetas y faltas), o null si aún no tiene nada
/// registrado ahí: el backend solo suma a quien tiene eventos de partido.
PlayerStatsModel? findPlayerStats(List<PlayerStatsModel> stats, String? playerId) {
  if (playerId == null || playerId.isEmpty) return null;
  for (final player in stats) {
    if (player.playerId == playerId) return player;
  }
  return null;
}
