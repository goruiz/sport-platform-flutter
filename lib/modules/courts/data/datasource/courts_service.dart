import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/network/response_parser.dart';
import '../models/court_model.dart';

class CourtsService {
  final DioClient _client = DioClient();

  Future<List<CourtModel>> getAll() async {
    final response = await _client.get(ApiEndpoints.courts);
    return ResponseParser.toList(response.data)
        .map((e) => CourtModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
