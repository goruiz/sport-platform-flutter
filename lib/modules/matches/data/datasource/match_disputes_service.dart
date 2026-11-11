import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/network/response_parser.dart';
import 'package:sport_platform/modules/matches/data/models/match_dispute_model.dart';

/// Los avisos de problema con el resultado de un partido. Solo el dirigente de equipo los abre y los ve; los rechazos
/// del backend llegan como excepción de la petición: el notifier los lee.
class MatchDisputesService {
  final DioClient _client;

  MatchDisputesService({DioClient? client}) : _client = client ?? DioClient();

  /// Los avisos de este partido que la cuenta puede ver: los de su equipo (de más nuevo a más antiguo).
  Future<List<MatchDisputeModel>> getByMatch(String matchId) async {
    final response = await _client.get(ApiEndpoints.matchDisputes(matchId));
    return [
      for (final item in ResponseParser.toList(response.data)) ?MatchDisputeModel.fromJson(item as Map<String, dynamic>),
    ];
  }

  /// El equipo [teamId] avisa de que el resultado está mal. [reason] es lo que pasó; el marcador que cree correcto es
  /// opcional, pero va completo (los dos goles) o no va.
  Future<MatchDisputeModel?> open(
    String matchId, {
    required String teamId,
    required String reason,
    int? proposedHomeScore,
    int? proposedAwayScore,
  }) async {
    final response = await _client.post(
      ApiEndpoints.matchDisputes(matchId),
      data: {
        'teamId': teamId,
        'reason': reason,
        'proposedHomeScore': ?proposedHomeScore,
        'proposedAwayScore': ?proposedAwayScore,
      },
    );
    return MatchDisputeModel.fromJson(ResponseParser.toMap(response.data));
  }
}
