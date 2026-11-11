import 'package:sport_platform/modules/users/domain/entities/user_entity.dart';
import 'package:sport_platform/modules/users/domain/entities/user_profile_update.dart';

abstract interface class IUserProfileRepository {
  /// Guarda los datos del perfil del usuario autenticado y devuelve el usuario actualizado.
  Future<UserEntity> updateProfile(UserProfileUpdate update);

  /// Lee la cuenta del usuario autenticado tal como está en el backend. El token solo trae lo que había al iniciar sesión
  /// (sin el género ni la fecha de nacimiento), así que de aquí sale lo que el formulario de edición muestra.
  Future<UserEntity> getCurrentAccount();
}
