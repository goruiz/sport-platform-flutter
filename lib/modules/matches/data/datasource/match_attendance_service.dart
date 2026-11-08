import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/network/response_parser.dart';
import 'package:sport_platform/modules/matches/data/models/match_attendance_model.dart';

/// La asistencia a un partido: quiénes confirmaron y la respuesta del propio jugador. Los rechazos del backend llegan
/// como excepción de la petición: el notifier los lee.
class MatchAttendanceService {
  /// El campo del cuerpo con la respuesta del jugador.
  static const String _statusField = 'status';

  final DioClient _client;

  MatchAttendanceService({DioClient? client}) : _client = client ?? DioClient();

  Future<MatchAttendanceModel> get(String matchId) async {
    final response = await _client.get(ApiEndpoints.matchAttendance(matchId));
    return MatchAttendanceModel.fromJson(ResponseParser.toMap(response.data));
  }

  /// Guarda (o cambia) la respuesta del jugador de la cuenta y devuelve la asistencia al día.
  Future<MatchAttendanceModel> respond(String matchId, AttendanceStatus status) async {
    final response = await _client.put(
      ApiEndpoints.matchAttendance(matchId),
      data: {_statusField: status.apiValue},
    );
    return MatchAttendanceModel.fromJson(ResponseParser.toMap(response.data));
  }

  /// Quita la respuesta del jugador de la cuenta y devuelve la asistencia al día.
  Future<MatchAttendanceModel> withdraw(String matchId) async {
    final response = await _client.delete(ApiEndpoints.matchAttendance(matchId));
    return MatchAttendanceModel.fromJson(ResponseParser.toMap(response.data));
  }
}
