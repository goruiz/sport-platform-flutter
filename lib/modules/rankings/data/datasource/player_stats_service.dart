import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/network/response_parser.dart';
import 'package:sport_platform/modules/rankings/data/models/player_stats_model.dart';

class PlayerStatsService {
  final DioClient _client;

  PlayerStatsService({DioClient? client}) : _client = client ?? DioClient();

  /// Los jugadores de un evento que tienen algo que mostrar (un gol, una tarjeta…).
  Future<List<PlayerStatsModel>> getByEvent(String eventId) async {
    final response = await _client.get(ApiEndpoints.playerStatsByEvent(eventId));
    return ResponseParser.toList(response.data)
        .map((item) => PlayerStatsModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
