import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/network/response_parser.dart';
import 'package:sport_platform/core/utils/date_formatters.dart';
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

  /// Los partidos programados en una cancha, por fecha. Con [from] solo los que empiezan ese día y hora o después
  /// (lo que sirve para ver lo que viene sin traer el historial).
  Future<List<MatchModel>> getByCourt(String courtId, {DateTime? from}) => _read(
        ApiEndpoints.matchesByCourt(courtId),
        queryParams: {if (from != null) 'from': DateFormatters.apiDateTime(from)},
      );

  Future<List<MatchModel>> _read(String path, {Map<String, dynamic>? queryParams}) async {
    final response = await _client.get(path, queryParams: queryParams);
    final matches = ResponseParser.toList(response.data)
        .map((item) => MatchModel.fromJson(item as Map<String, dynamic>))
        .toList();
    matches.sort((a, b) => a.matchDate.compareTo(b.matchDate));
    return matches;
  }
}
