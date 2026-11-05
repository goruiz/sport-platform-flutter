import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/network/response_parser.dart';

/// Entrar a un equipo con el código que dio su administrador. Un rechazo llega como excepción de la petición;
/// `JoinTeamError.fromException` dice cuál fue.
class JoinTeamService {
  final DioClient _client;

  JoinTeamService({DioClient? client}) : _client = client ?? DioClient();

  /// El jugador entra al equipo del código. Devuelve la sesión nueva que manda el backend: la organización de la cuenta
  /// viaja en el token y ahora es la del equipo.
  Future<String?> join(String code) async {
    final response = await _client.post(ApiEndpoints.playersJoinByCode, data: {'code': code});
    return ResponseParser.toMap(response.data)['token'] as String?;
  }
}
