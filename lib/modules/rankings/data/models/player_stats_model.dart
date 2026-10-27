/// Lo que hizo un jugador en todos los partidos de un evento, sumado por el backend.
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
  });

  int get cards => yellowCards + redCards;

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
    );
  }

  static int _asInt(dynamic value) => value is num ? value.toInt() : 0;
}
