import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/network/response_parser.dart';
import 'package:sport_platform/core/utils/date_formatters.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/repositories/i_league_matches_repository.dart';
import '../models/match_model.dart';

class LeagueMatchesService implements ILeagueMatchesRepository {
  final DioClient _client = DioClient();

  @override
  Future<List<MatchModel>> getByEvent(String eventId) async {
    final response = await _client.get(ApiEndpoints.matchesByEvent(eventId));
    return ResponseParser.toList(response.data)
        .map((e) => MatchModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MatchModel> create(Map<String, dynamic> data) async {
    final response = await _client.post(ApiEndpoints.matches, data: data);
    return MatchModel.fromJson(ResponseParser.toMap(response.data));
  }

  @override
  Future<MatchModel> update(String id, Map<String, dynamic> data) async {
    final response = await _client.put(ApiEndpoints.matchById(id), data: data);
    return MatchModel.fromJson(ResponseParser.toMap(response.data));
  }

  @override
  Future<void> delete(String id) async {
    await _client.delete(ApiEndpoints.matchById(id));
  }

  /// [toDate] null → aplaza (POSTPONED). Con fecha → reprograma a esa fecha.
  @override
  Future<List<MatchModel>> rescheduleDate(
    String eventId,
    DateTime fromDate, {
    DateTime? toDate,
  }) async {
    final response = await _client.patch(
      ApiEndpoints.rescheduleDateMatches(eventId),
      data: {
        'fromDate': DateFormatters.apiDate(fromDate),
        if (toDate != null) 'toDate': DateFormatters.apiDate(toDate),
      },
    );
    return ResponseParser.toList(response.data)
        .map((e) => MatchModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MatchModel> postpone(String id) async {
    final response = await _client.patch(ApiEndpoints.matchPostpone(id));
    return MatchModel.fromJson(ResponseParser.toMap(response.data));
  }

  @override
  Future<MatchModel> suspend(String id) async {
    final response = await _client.patch(ApiEndpoints.matchSuspend(id));
    return MatchModel.fromJson(ResponseParser.toMap(response.data));
  }

  @override
  Future<MatchModel> reschedule(String id, DateTime newDate) async {
    final response = await _client.patch(
      ApiEndpoints.matchReschedule(id),
      data: {'newDate': MatchModel.apiDateTime(newDate)},
    );
    return MatchModel.fromJson(ResponseParser.toMap(response.data));
  }
}
