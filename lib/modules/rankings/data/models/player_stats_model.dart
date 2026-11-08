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
    return PlayerStatsModel(
      playerId: json['playerId']?.toString() ?? '',
      playerName: json['playerName']?.toString(),
      teamId: json['teamId']?.toString() ?? '',
      teamName: json['teamName']?.toString(),
      goals: _asInt(json['goals']),
      assists: _asInt(json['assists']),
      yellowCards: _asInt(json['yellowCards']),
      redCards: _asInt(json['redCards']),
      fouls: _asInt(json['fouls']),
      matchesPlayed: _asInt(json['matchesPlayed']),
    );
  }

  static int _asInt(dynamic value) => value is num ? value.toInt() : 0;
}
