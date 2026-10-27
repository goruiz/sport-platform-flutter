import 'package:sport_platform/modules/matches/domain/enums/match_event_type.dart';

/// Una línea de la cronología de un partido: un gol, una asistencia, una tarjeta o una falta.
class MatchEventModel {
  final String id;
  final String matchId;
  final String playerId;

  /// Null si el jugador se borró después de jugar.
  final String? playerName;
  final String teamId;

  /// Null si el backend trae un tipo desconocido para esta versión de la app.
  final MatchEventType? type;
  final int? minute;
  final String? notes;

  const MatchEventModel({
    required this.id,
    required this.matchId,
    required this.playerId,
    this.playerName,
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
      teamId: json['teamId']?.toString() ?? '',
      type: MatchEventType.fromApi(json['eventType']?.toString()),
      minute: json['minute'] is num ? (json['minute'] as num).toInt() : null,
      notes: json['notes']?.toString(),
    );
  }
}
