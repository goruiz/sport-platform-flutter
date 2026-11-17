import 'package:sport_platform/core/network/json_reader.dart';

class StandingModel {
  final int position;
  final String teamId;
  final String teamName;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;

  const StandingModel({
    required this.position,
    required this.teamId,
    required this.teamName,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
  });

  factory StandingModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, resource: 'posición');
    return StandingModel(
      position: reader.requiredInt('position'),
      teamId: reader.requiredString('teamId'),
      teamName: reader.requiredString('teamName'),
      played: reader.requiredInt('played'),
      won: reader.requiredInt('won'),
      drawn: reader.requiredInt('drawn'),
      lost: reader.requiredInt('lost'),
      goalsFor: reader.requiredInt('goalsFor'),
      goalsAgainst: reader.requiredInt('goalsAgainst'),
      goalDifference: reader.requiredInt('goalDifference'),
      points: reader.requiredInt('points'),
    );
  }
}
