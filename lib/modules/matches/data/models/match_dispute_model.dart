/// En qué va un aviso de problema con el resultado (una «disputa»). El backend lo guarda por nombre.
enum DisputeStatus {
  /// El organizador todavía no responde.
  open('OPEN'),

  /// El organizador le dio la razón al equipo (y corrigió el resultado si hacía falta).
  accepted('ACCEPTED'),

  /// El organizador revisó el aviso y el resultado se mantiene.
  rejected('REJECTED');

  const DisputeStatus(this.apiValue);

  final String apiValue;

  /// El estado que manda el backend; null si es un valor que la app no conoce.
  static DisputeStatus? fromApi(Object? value) {
    for (final status in values) {
      if (status.apiValue == value) return status;
    }
    return null;
  }
}

/// Un aviso que un equipo hizo sobre el resultado de un partido, con lo que el organizador respondió.
class MatchDisputeModel {
  final String id;
  final String matchId;
  final DisputeStatus status;

  /// El equipo que avisó.
  final String teamId;
  final String reason;

  /// El marcador que el equipo dice que es el correcto; los dos o ninguno.
  final int? proposedHomeScore;
  final int? proposedAwayScore;
  final DateTime createdAt;

  /// Lo que respondió el organizador; null mientras no responde (y puede venir vacío si aceptó sin nota).
  final String? resolutionNote;
  final DateTime? resolvedAt;

  const MatchDisputeModel({
    required this.id,
    required this.matchId,
    required this.status,
    required this.teamId,
    required this.reason,
    this.proposedHomeScore,
    this.proposedAwayScore,
    required this.createdAt,
    this.resolutionNote,
    this.resolvedAt,
  });

  bool get isOpen => status == DisputeStatus.open;

  bool get hasProposedScore => proposedHomeScore != null && proposedAwayScore != null;

  /// Null si trae un estado desconocido: no hay forma de mostrarlo.
  static MatchDisputeModel? fromJson(Map<String, dynamic> json) {
    final status = DisputeStatus.fromApi(json['status']);
    if (status == null) return null;
    return MatchDisputeModel(
      id: json['id']?.toString() ?? '',
      matchId: json['matchId']?.toString() ?? '',
      status: status,
      teamId: json['teamId']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      proposedHomeScore: _asInt(json['proposedHomeScore']),
      proposedAwayScore: _asInt(json['proposedAwayScore']),
      createdAt: _asDateTime(json['createdAt']) ?? DateTime.now(),
      resolutionNote: json['resolutionNote']?.toString(),
      resolvedAt: _asDateTime(json['resolvedAt']),
    );
  }

  static int? _asInt(Object? value) => value is num ? value.toInt() : null;

  static DateTime? _asDateTime(Object? value) => value == null ? null : DateTime.tryParse(value.toString());
}
