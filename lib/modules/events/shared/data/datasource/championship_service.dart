import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/network/response_parser.dart';
import 'package:sport_platform/modules/events/shared/data/models/championship_model.dart';

class ChampionshipService {
  final DioClient _client;

  ChampionshipService({DioClient? client}) : _client = client ?? DioClient();

  Future<ChampionshipModel> getByEvent(String eventId) async {
    final response = await _client.get(ApiEndpoints.championshipByEvent(eventId));
    return ChampionshipModel.fromJson(ResponseParser.toMap(response.data));
  }
}
