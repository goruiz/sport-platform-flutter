import 'package:dio/dio.dart';
import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/network/response_parser.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/events/shared/domain/event_rules.dart';
import 'package:sport_platform/modules/matches/data/datasource/matches_service.dart';
import 'package:sport_platform/modules/matches/domain/match_rules.dart';

/// Los eventos en que juega un equipo. El backend no los lista por equipo: salen de los partidos del jugador
/// (`GET /matches/mine` trae el `eventId` de cada uno) y cada evento se lee por su id, así que no dependen de en qué página
/// de la búsqueda caerían. Un equipo inscrito cuyo evento aún no tiene partidos no aparece hasta que los tenga.
class TeamEventsService {
  final MatchesService _matchesService;
  final DioClient _client;

  TeamEventsService({MatchesService? matchesService, DioClient? client})
      : _matchesService = matchesService ?? MatchesService(),
        _client = client ?? DioClient();

  /// Los eventos de [teamId], en el orden en que los lista el backend: lo que está en curso primero, luego lo que viene
  /// y al final lo que ya terminó.
  Future<List<EventModel>> getOfTeam(String teamId) async =>
      getOfMatches(await _matchesService.getMine(), teamId);

  /// Lo mismo que [getOfTeam] para quien ya leyó los partidos del jugador ([matches], los de todos sus equipos): no los
  /// vuelve a pedir.
  Future<List<EventModel>> getOfMatches(Iterable<MatchModel> matches, String teamId) async {
    final eventIds = eventIdsOfTeam(matches, teamId);
    final events = await Future.wait(eventIds.map(_getById));
    return [
      for (final event in events) ?event,
    ]..sort(compareEventsByRelevance);
  }

  /// Un evento por su id, o null si el jugador ya no lo ve (un 404 del backend significa "no existe", no un error).
  Future<EventModel?> _getById(String id) async {
    try {
      final response = await _client.get(ApiEndpoints.eventById(id));
      return EventModel.fromJson(ResponseParser.toMap(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
