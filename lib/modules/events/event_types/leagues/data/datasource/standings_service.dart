import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/network/response_parser.dart';
import '../models/standing_model.dart';

class StandingsService {
  final DioClient _client = DioClient();

  Future<List<StandingModel>> getAll() async {
    final response = await _client.get(ApiEndpoints.standings);
    return ResponseParser.toList(
      response.data,
    ).map((e) => StandingModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<StandingModel>> getById(String id) async {
    final response = await _client.get(ApiEndpoints.standingsByEvent(id));
    return ResponseParser.toList(
      response.data,
    ).map((e) => StandingModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
