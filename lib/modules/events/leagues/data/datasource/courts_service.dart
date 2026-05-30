import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import '../models/court_model.dart';

class CourtsService {
  final DioClient _client = DioClient();

  Future<List<CourtModel>> getAll() async {
    final response = await _client.get(ApiEndpoints.courts);
    final dynamic raw = response.data;
    final List<dynamic> list =
        raw is List ? raw : (raw['data'] as List<dynamic>);
    return list
        .map((e) => CourtModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
