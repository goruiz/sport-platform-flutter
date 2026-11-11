import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/users/domain/birth_date_rules.dart';
import 'package:sport_platform/modules/users/domain/enums/gender.dart';

class PlayersAuthService {
  final DioClient _client = DioClient();

  /// Public endpoint — no auth required.
  /// The backend validates [inviteToken], creates the player, and assigns
  /// them to the team associated with the token automatically.
  ///
  /// [gender] and [birthDate] are what the team's category may ask about: the backend checks them BEFORE creating the
  /// account, so a registration the category refuses leaves nothing behind (400 with a `CATEGORY_*` message).
  Future<PlayerModel> registerWithToken({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String inviteToken,
    String? phone,
    Gender? gender,
    DateTime? birthDate,
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
        if (gender != null) 'gender': gender.apiValue,
        if (birthDate != null) 'birthDate': formatBirthDateForApi(birthDate),
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
