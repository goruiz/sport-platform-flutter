import 'package:sport_platform/core/network/json_reader.dart';

class TeamEventModel {
  final String id;
  final String teamId;
  final String teamName;
  final String eventId;
  final DateTime createdAt;

  const TeamEventModel({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.eventId,
    required this.createdAt,
  });

  factory TeamEventModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, resource: 'inscripción de equipo');
    return TeamEventModel(
      id: reader.requiredString('id'),
      teamId: reader.requiredString('teamId'),
      teamName: reader.requiredString('teamName'),
      eventId: reader.requiredString('eventId'),
      createdAt: reader.requiredDateTime('createdAt'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'teamId': teamId,
        'teamName': teamName,
        'eventId': eventId,
        'createdAt': createdAt.toIso8601String(),
      };

  TeamEventModel copyWith({
    String? id,
    String? teamId,
    String? teamName,
    String? eventId,
    DateTime? createdAt,
  }) =>
      TeamEventModel(
        id: id ?? this.id,
        teamId: teamId ?? this.teamId,
        teamName: teamName ?? this.teamName,
        eventId: eventId ?? this.eventId,
        createdAt: createdAt ?? this.createdAt,
      );
}
