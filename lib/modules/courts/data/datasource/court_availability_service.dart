import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/network/response_parser.dart';
import 'package:sport_platform/core/utils/date_formatters.dart';
import 'package:sport_platform/modules/courts/data/models/court_availability_model.dart';

class CourtAvailabilityService {
  final DioClient _client;

  CourtAvailabilityService({DioClient? client}) : _client = client ?? DioClient();

  /// Cómo está [day] en la cancha: cuándo abre, qué ocupan los partidos y qué queda libre.
  Future<CourtAvailabilityModel> getByDay(String courtId, DateTime day) async {
    final response = await _client.get(
      ApiEndpoints.courtAvailability(courtId),
      queryParams: {'date': DateFormatters.apiDate(day)},
    );
    return CourtAvailabilityModel.fromJson(ResponseParser.toMap(response.data));
  }
}
