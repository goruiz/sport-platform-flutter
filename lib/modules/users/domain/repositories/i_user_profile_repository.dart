import 'package:sport_platform/modules/users/domain/entities/user_entity.dart';
import 'package:sport_platform/modules/users/domain/entities/user_profile_update.dart';

abstract interface class IUserProfileRepository {
  /// Guarda los datos del perfil del usuario autenticado y devuelve el usuario actualizado.
  Future<UserEntity> updateProfile(UserProfileUpdate update);
}
