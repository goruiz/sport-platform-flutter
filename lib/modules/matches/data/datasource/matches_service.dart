import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/network/response_parser.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';

class MatchesService {
  final DioClient _client;

  MatchesService({DioClient? client}) : _client = client ?? DioClient();

  /// Los partidos del equipo del jugador en sesión, de todos los eventos, por fecha. Vacío si el
  /// jugador aún no tiene equipo.
  Future<List<MatchModel>> getMine() => _read(ApiEndpoints.matchesMine);

  /// Los partidos de un evento, por fecha. Una lista acotada por el evento: ya no hay lectura de todos los de la
  /// plataforma (con los eventos públicos de muchas organizaciones crecería sin tope).
  Future<List<MatchModel>> getByEvent(String eventId) =>
      _read(ApiEndpoints.matchesByEvent(eventId));

  Future<List<MatchModel>> _read(String path) async {
    final response = await _client.get(path);
    final matches = ResponseParser.toList(response.data)
        .map((item) => MatchModel.fromJson(item as Map<String, dynamic>))
        .toList();
    matches.sort((a, b) => a.matchDate.compareTo(b.matchDate));
    return matches;
  }
}
