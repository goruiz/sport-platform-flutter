import 'package:sport_platform/core/network/json_reader.dart';

/// Lo que hizo un jugador, sumado por el backend: en todos los partidos de un evento o, si viene de sus totales
/// (`GET /players/me/stats`), en todos los eventos en que jugó.
class PlayerStatsModel {
  final String playerId;

  /// Null si el jugador se borró después de jugar.
  final String? playerName;
  final String teamId;
  final String? teamName;
  final int goals;
  final int assists;
  final int yellowCards;
  final int redCards;
  final int fouls;

  /// Los partidos ya jugados por su equipo (en el evento o en total). 0 si el backend no lo manda.
  final int matchesPlayed;

  const PlayerStatsModel({
    required this.playerId,
    this.playerName,
    required this.teamId,
    this.teamName,
    this.goals = 0,
    this.assists = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.fouls = 0,
    this.matchesPlayed = 0,
  });

  int get cards => yellowCards + redCards;

  /// No tiene nada que mostrar: ni partidos jugados ni un solo gol, tarjeta o falta.
  bool get isEmpty => matchesPlayed + goals + assists + yellowCards + redCards + fouls == 0;

  factory PlayerStatsModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, resource: 'estadísticas de jugador');
    // Una cifra que no llega es que no hubo nada que contar: cero.
    int count(String field) => reader.optionalInt(field) ?? 0;
    return PlayerStatsModel(
      playerId: reader.requiredString('playerId'),
      playerName: reader.optionalString('playerName'),
      teamId: reader.requiredString('teamId'),
      teamName: reader.optionalString('teamName'),
      goals: count('goals'),
      assists: count('assists'),
      yellowCards: count('yellowCards'),
      redCards: count('redCards'),
      fouls: count('fouls'),
      matchesPlayed: count('matchesPlayed'),
    );
  }
}
