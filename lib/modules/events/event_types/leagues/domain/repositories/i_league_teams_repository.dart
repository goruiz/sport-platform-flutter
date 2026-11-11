import '../../data/models/team_event_model.dart';

abstract interface class ILeagueTeamsRepository {
  Future<List<TeamEventModel>> getByEvent(String eventId);
}
