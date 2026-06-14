import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/network/response_parser.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/repositories/i_league_teams_repository.dart';
import '../models/team_event_model.dart';

class LeagueTeamsEventService implements ILeagueTeamsRepository {
  final DioClient _client = DioClient();

  @override
  Future<List<TeamEventModel>> getByEvent(String eventId) async {
    final response = await _client.get(ApiEndpoints.teamsEventsByEvent(eventId));
    return ResponseParser.toList(response.data)
        .map((e) => TeamEventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<TeamEventModel> add(String teamId, String eventId) async {
    final response = await _client.post(
      ApiEndpoints.teamsEvents,
      data: {'teamId': teamId, 'eventId': eventId},
    );
    return TeamEventModel.fromJson(ResponseParser.toMap(response.data));
  }

  @override
  Future<void> remove(String teamsEventsId) async {
    await _client.delete(ApiEndpoints.teamsEventsHardDelete(teamsEventsId));
  }
}
