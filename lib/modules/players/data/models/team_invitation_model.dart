/// Una invitación a unirse a un equipo, vista por la persona invitada.
class TeamInvitationModel {
  final String id;
  final String teamId;

  /// Null si el equipo ya no existe.
  final String? teamName;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  const TeamInvitationModel({
    required this.id,
    required this.teamId,
    this.teamName,
    this.expiresAt,
    this.createdAt,
  });

  factory TeamInvitationModel.fromJson(Map<String, dynamic> json) {
    return TeamInvitationModel(
      id: json['id']?.toString() ?? '',
      teamId: json['teamId']?.toString() ?? '',
      teamName: json['teamName']?.toString(),
      expiresAt: _parseDate(json['expiresAt']),
      createdAt: _parseDate(json['createdAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) =>
      value == null ? null : DateTime.tryParse(value.toString());
}
