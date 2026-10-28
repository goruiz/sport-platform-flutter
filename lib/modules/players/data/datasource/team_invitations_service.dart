import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/network/response_parser.dart';
import 'package:sport_platform/modules/players/data/models/team_invitation_model.dart';

class TeamInvitationsService {
  final DioClient _client;

  TeamInvitationsService({DioClient? client}) : _client = client ?? DioClient();

  /// Las invitaciones que el usuario en sesión aún puede responder.
  Future<List<TeamInvitationModel>> getMine() async {
    final response = await _client.get(ApiEndpoints.teamInvitationsMine);
    return ResponseParser.toList(response.data)
        .map((item) => TeamInvitationModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// El jugador entra al equipo que lo invitó (y sale del que tenía). Devuelve la sesión nueva que manda el
  /// backend, porque la organización de la cuenta viaja en el token y ahora es la del equipo; null si no la manda.
  Future<String?> accept(String invitationId) async {
    final response = await _client.post(ApiEndpoints.teamInvitationAccept(invitationId));
    return ResponseParser.toMap(response.data)['token'] as String?;
  }

  Future<void> decline(String invitationId) async {
    await _client.post(ApiEndpoints.teamInvitationDecline(invitationId));
  }
}
