import 'package:sport_platform/modules/matches/domain/enums/match_event_type.dart';

/// Una línea de la cronología de un partido: un gol, una asistencia, una tarjeta, una falta o un cambio.
class MatchEventModel {
  final String id;
  final String matchId;
  final String playerId;

  /// Null si el jugador se borró después de jugar. En un cambio es quien ENTRA.
  final String? playerName;

  /// Solo en un cambio: quien SALE. Null en las demás líneas, o si el jugador se borró.
  final String? replacedPlayerId;
  final String? replacedPlayerName;
  final String teamId;

  /// Null si el backend trae un tipo desconocido para esta versión de la app.
  final MatchEventType? type;
  final int? minute;
  final String? notes;

  /// Es un cambio de jugador (la línea dice quién entra y quién sale).
  bool get isSubstitution => type == MatchEventType.substitution;

  const MatchEventModel({
    required this.id,
    required this.matchId,
    required this.playerId,
    this.playerName,
    this.replacedPlayerId,
    this.replacedPlayerName,
    required this.teamId,
    required this.type,
    this.minute,
    this.notes,
  });

  factory MatchEventModel.fromJson(Map<String, dynamic> json) {
    return MatchEventModel(
      id: json['id']?.toString() ?? '',
      matchId: json['matchId']?.toString() ?? '',
      playerId: json['playerId']?.toString() ?? '',
      playerName: json['playerName']?.toString(),
      replacedPlayerId: json['replacedPlayerId']?.toString(),
      replacedPlayerName: json['replacedPlayerName']?.toString(),
      teamId: json['teamId']?.toString() ?? '',
      type: MatchEventType.fromApi(json['eventType']?.toString()),
      minute: json['minute'] is num ? (json['minute'] as num).toInt() : null,
      notes: json['notes']?.toString(),
    );
  }
}
