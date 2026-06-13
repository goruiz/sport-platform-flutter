import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/network/response_parser.dart';
import '../models/team_model.dart';

class TeamsService {
  final DioClient _client = DioClient();

  Future<List<TeamModel>> getAll() async {
    final response = await _client.get(ApiEndpoints.teams);
    return ResponseParser.toList(response.data)
        .map((e) => TeamModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TeamModel> create(String name, {String? logoUrl}) async {
    final response = await _client.post(
      ApiEndpoints.teams,
      data: {
        'name': name,
        if (logoUrl != null && logoUrl.isNotEmpty) 'logoUrl': logoUrl,
      },
    );
    return TeamModel.fromJson(ResponseParser.toMap(response.data));
  }
}
