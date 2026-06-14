import '../../data/models/team_event_model.dart';

abstract interface class ILeagueTeamsRepository {
  Future<List<TeamEventModel>> getByEvent(String eventId);
  Future<TeamEventModel> add(String teamId, String eventId);
  Future<void> remove(String teamsEventsId);
}
