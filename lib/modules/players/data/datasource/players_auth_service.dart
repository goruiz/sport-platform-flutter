import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';

class PlayersAuthService {
  final DioClient _client = DioClient();

  /// Public endpoint — no auth required.
  /// The backend validates [inviteToken], creates the player, and assigns
  /// them to the team associated with the token automatically.
  Future<PlayerModel> registerWithToken({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String inviteToken,
    String? phone,
  }) async {
    final response = await _client.post(
      ApiEndpoints.playersAuthRegister,
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'inviteToken': inviteToken,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
    final dynamic raw = response.data;
    final Map<String, dynamic> data =
        raw is Map<String, dynamic> && raw.containsKey('data')
            ? raw['data'] as Map<String, dynamic>
            : raw as Map<String, dynamic>;
    return PlayerModel.fromJson(data);
  }
}
