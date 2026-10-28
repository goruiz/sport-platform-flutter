import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/network/response_parser.dart';
import 'package:sport_platform/modules/sport_complexes/data/models/sport_complex_model.dart';

class SportComplexesService {
  final DioClient _client;

  SportComplexesService({DioClient? client}) : _client = client ?? DioClient();

  /// Los complejos que el jugador ve: los de su organización.
  Future<List<SportComplexModel>> getAll() async {
    final response = await _client.get(ApiEndpoints.sportComplexes);
    return ResponseParser.toList(response.data)
        .map((item) => SportComplexModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
