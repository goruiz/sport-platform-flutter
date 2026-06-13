import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import '../models/event_schedule_config_model.dart';
import '../models/team_event_model.dart';
import '../models/match_model.dart';

class LeagueDetailService {
  final DioClient _client = DioClient();

  Future<List<TeamEventModel>> getTeamsByEvent(String eventId) async {
    final response =
        await _client.get(ApiEndpoints.teamsEventsByEvent(eventId));
    final dynamic raw = response.data;
    final List<dynamic> list =
        raw is List ? raw : (raw['data'] as List<dynamic>);
    return list
        .map((e) => TeamEventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TeamEventModel> addTeam(String teamId, String eventId) async {
    final response = await _client.post(
      ApiEndpoints.teamsEvents,
      data: {'teamId': teamId, 'eventId': eventId},
    );
    return TeamEventModel.fromJson(_unwrap(response.data));
  }

  Future<void> removeTeam(String teamsEventsId) async {
    await _client.delete(ApiEndpoints.teamsEventsHardDelete(teamsEventsId));
  }

  Future<List<MatchModel>> getMatchesByEvent(String eventId) async {
    final response =
        await _client.get(ApiEndpoints.matchesByEvent(eventId));
    final dynamic raw = response.data;
    final List<dynamic> list =
        raw is List ? raw : (raw['data'] as List<dynamic>);
    return list
        .map((e) => MatchModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MatchModel> createMatch(Map<String, dynamic> data) async {
    final response = await _client.post(ApiEndpoints.matches, data: data);
    return MatchModel.fromJson(_unwrap(response.data));
  }

  Future<MatchModel> updateMatch(String id, Map<String, dynamic> data) async {
    final response = await _client.put(ApiEndpoints.matchById(id), data: data);
    return MatchModel.fromJson(_unwrap(response.data));
  }

  Future<void> deleteMatch(String id) async {
    await _client.delete(ApiEndpoints.matchById(id));
  }

  Future<EventScheduleConfigModel?> getScheduleConfig(String eventId) async {
    try {
      final response =
          await _client.get(ApiEndpoints.scheduleConfig(eventId));
      return EventScheduleConfigModel.fromJson(_unwrap(response.data));
    } catch (_) {
      return null;
    }
  }

  Future<EventScheduleConfigModel> saveScheduleConfig(
      String eventId, Map<String, dynamic> data) async {
    final response = await _client.post(
      ApiEndpoints.scheduleConfig(eventId),
      data: data,
    );
    return EventScheduleConfigModel.fromJson(_unwrap(response.data));
  }

  Future<List<MatchModel>> generateSchedule(String eventId) async {
    final response =
        await _client.post(ApiEndpoints.generateSchedule(eventId));
    final dynamic raw = response.data;
    final List<dynamic> list =
        raw is List ? raw : (raw['data'] as List<dynamic>);
    return list
        .map((e) => MatchModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// [toDate] null → aplaza (POSTPONED). Con fecha → reprograma a esa fecha.
  Future<List<MatchModel>> rescheduleDateMatches(
      String eventId, DateTime fromDate, {DateTime? toDate}) async {
    final response = await _client.patch(
      ApiEndpoints.rescheduleDateMatches(eventId),
      data: {
        'fromDate': _isoDate(fromDate),
        if (toDate != null) 'toDate': _isoDate(toDate),
      },
    );
    final dynamic raw = response.data;
    final List<dynamic> list =
        raw is List ? raw : (raw['data'] as List<dynamic>);
    return list
        .map((e) => MatchModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Map<String, dynamic> _unwrap(dynamic raw) {
    final map = raw as Map<String, dynamic>;
    if (map['data'] is Map<String, dynamic>) {
      return map['data'] as Map<String, dynamic>;
    }
    return map;
  }
}
