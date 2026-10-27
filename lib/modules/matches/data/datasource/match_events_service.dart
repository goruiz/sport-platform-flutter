import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/network/response_parser.dart';
import 'package:sport_platform/modules/matches/data/models/match_event_model.dart';

/// La cronología de un partido. La app solo la lee: quien registra los goles y las tarjetas es el
/// organizador desde el panel.
class MatchEventsService {
  final DioClient _client;

  MatchEventsService({DioClient? client}) : _client = client ?? DioClient();

  /// La cronología del partido, en el orden en que pasaron las cosas.
  Future<List<MatchEventModel>> getByMatch(String matchId) async {
    final response = await _client.get(ApiEndpoints.matchEventsByMatch(matchId));
    return ResponseParser.toList(response.data)
        .map((item) => MatchEventModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
