import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/network/response_parser.dart';
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
}
