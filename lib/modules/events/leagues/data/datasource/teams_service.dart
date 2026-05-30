import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import '../models/team_model.dart';

class TeamsService {
  final DioClient _client = DioClient();

  Future<List<TeamModel>> getAll() async {
    final response = await _client.get(ApiEndpoints.teams);
    final dynamic raw = response.data;
    final List<dynamic> list =
        raw is List ? raw : (raw['data'] as List<dynamic>);
    return list
        .map((e) => TeamModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
