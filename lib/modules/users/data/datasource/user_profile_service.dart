import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/network/response_parser.dart';
import 'package:sport_platform/modules/users/data/models/user_model.dart';
import 'package:sport_platform/modules/users/domain/entities/user_entity.dart';
import 'package:sport_platform/modules/users/domain/entities/user_profile_update.dart';
import 'package:sport_platform/modules/users/domain/repositories/i_user_profile_repository.dart';

class UserProfileService implements IUserProfileRepository {
  final DioClient _client;

  UserProfileService({DioClient? client}) : _client = client ?? DioClient();

  @override
  Future<UserEntity> updateProfile(UserProfileUpdate update) async {
    final response = await _client.put(
      ApiEndpoints.updateProfile,
      data: _toRequestBody(update),
    );
    return UserModel.fromJson(ResponseParser.toMap(response.data));
  }

  // El backend ignora los campos nulos al actualizar: los opcionales vacíos se omiten
  // en vez de enviarse como "", que sí sobrescribirían el valor guardado.
  Map<String, dynamic> _toRequestBody(UserProfileUpdate update) => {
        'firstName': update.firstName,
        if (_hasText(update.middleName)) 'middleName': update.middleName,
        'lastName': update.lastName,
        if (_hasText(update.secondLastName))
          'secondLastName': update.secondLastName,
        'username': update.username,
      };

  bool _hasText(String? value) => value != null && value.isNotEmpty;
}
