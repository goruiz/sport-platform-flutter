import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/network/response_parser.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/repositories/i_league_schedule_repository.dart';
import '../models/event_schedule_config_model.dart';
import '../models/match_model.dart';

class LeagueScheduleService implements ILeagueScheduleRepository {
  final DioClient _client = DioClient();

  @override
  Future<EventScheduleConfigModel?> getConfig(String eventId) async {
    try {
      final response = await _client.get(ApiEndpoints.scheduleConfig(eventId));
      return EventScheduleConfigModel.fromJson(ResponseParser.toMap(response.data));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<EventScheduleConfigModel> saveConfig(
      String eventId, Map<String, dynamic> data) async {
    final response = await _client.post(
      ApiEndpoints.scheduleConfig(eventId),
      data: data,
    );
    return EventScheduleConfigModel.fromJson(ResponseParser.toMap(response.data));
  }

  @override
  Future<(List<MatchModel>, String?)> generate(String eventId) async {
    final response = await _client.post(ApiEndpoints.generateSchedule(eventId));
    final data = ResponseParser.toMap(response.data);
    final matches = (data['matches'] as List<dynamic>)
        .map((e) => MatchModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final warning = data['warning'] as String?;
    return (matches, warning);
  }
}
