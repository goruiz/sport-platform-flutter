import 'package:dio/dio.dart';
import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/network/response_parser.dart';
import '../models/team_model.dart';

class TeamsService {
  final DioClient _client = DioClient();

  /// Un equipo por su id, o null si el jugador no lo ve (un 404 del backend significa "no existe", no un error).
  Future<TeamModel?> getById(String id) async {
    try {
      final response = await _client.get(ApiEndpoints.teamById(id));
      return TeamModel.fromJson(ResponseParser.toMap(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
