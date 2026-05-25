import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import '../models/league_model.dart';

class LeagueService {
  final DioClient _client = DioClient();

  Future<List<LeagueModel>> getAll() async {
    final response = await _client.get(ApiEndpoints.leagues);
    final dynamic raw = response.data;
    final List<dynamic> list = raw is List ? raw : (raw['data'] as List<dynamic>);
    return list
        .map((e) => LeagueModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LeagueModel> create(Map<String, dynamic> data) async {
    final response = await _client.post(ApiEndpoints.leagues, data: data);
    final dynamic raw = response.data;
    final Map<String, dynamic> json =
        raw is Map<String, dynamic> ? raw : raw['data'] as Map<String, dynamic>;
    return LeagueModel.fromJson(json);
  }

  Future<LeagueModel> update(String id, Map<String, dynamic> data) async {
    final response =
        await _client.put(ApiEndpoints.leagueById(id), data: data);
    final dynamic raw = response.data;
    final Map<String, dynamic> json =
        raw is Map<String, dynamic> ? raw : raw['data'] as Map<String, dynamic>;
    return LeagueModel.fromJson(json);
  }

  Future<void> delete(String id) async {
    await _client.delete(ApiEndpoints.leagueById(id));
  }
}
