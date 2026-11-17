import 'package:sport_platform/core/network/json_reader.dart';

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
    final reader = JsonReader(json, resource: 'invitación');
    return TeamInvitationModel(
      id: reader.requiredString('id'),
      teamId: reader.requiredString('teamId'),
      teamName: reader.optionalString('teamName'),
      expiresAt: reader.optionalDateTime('expiresAt'),
      createdAt: reader.optionalDateTime('createdAt'),
    );
  }
}
