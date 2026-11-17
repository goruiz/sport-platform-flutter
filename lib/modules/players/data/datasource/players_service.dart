import 'package:dio/dio.dart';
import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/network/response_parser.dart';
import '../models/player_model.dart';

class PlayersService {
  final DioClient _client;

  PlayersService({DioClient? client}) : _client = client ?? DioClient();

  /// El jugador que corresponde a la cuenta con sesión iniciada, o null si la cuenta aún no tiene
  /// (un 404 del backend significa "no existe", no un error).
  Future<PlayerModel?> getCurrent() async {
    try {
      final response = await _client.get(ApiEndpoints.playersMe);
      return PlayerModel.fromJson(ResponseParser.toMap(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Saca al jugador de un equipo; los demás en los que juega (de otras organizaciones) se quedan. [teamId] dice
  /// de cuál: el backend lo exige solo si el jugador tiene varios que quien llama puede ver.
  Future<PlayerModel> removeFromTeam(String playerId, {String? teamId}) async {
    final response = await _client.patch(
      ApiEndpoints.playerRemoveFromTeam(playerId, teamId: teamId),
    );
    final dynamic raw = response.data;
    final Map<String, dynamic> data =
        raw is Map<String, dynamic> && raw.containsKey('data')
            ? raw['data'] as Map<String, dynamic>
            : raw as Map<String, dynamic>;
    return PlayerModel.fromJson(data);
  }

  Future<List<PlayerModel>> getByTeamId(String teamId) async {
    final response = await _client.get(ApiEndpoints.playersByTeam(teamId));
    final dynamic raw = response.data;
    final List<dynamic> list =
        raw is Map<String, dynamic> && raw.containsKey('data')
            ? raw['data'] as List<dynamic>
            : raw as List<dynamic>;
    return list
        .map((e) => PlayerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
