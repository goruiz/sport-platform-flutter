import 'package:sport_platform/core/services/auth_storage.dart';
import 'package:sport_platform/core/services/user_session.dart';

/// Cierra la sesión local: credenciales, usuario y estado en memoria del usuario anterior.
///
/// Lo usan el logout manual y la expiración de sesión, para que ambos dejen la app igual.
class SessionService {
  final void Function() _resetSessionScopedState;
  final void Function()? _resetOrganizationScopedState;

  /// [resetSessionScopedState] descarta el estado en memoria que pertenece al usuario
  /// (cachés, listas) para que no se le muestre al siguiente que inicie sesión.
  ///
  /// [resetOrganizationScopedState] descarta solo lo que depende de la organización de la cuenta
  /// (lo que el jugador ve en la app), para cuando esa organización cambia sin cerrar la sesión.
  SessionService({
    required void Function() resetSessionScopedState,
    void Function()? resetOrganizationScopedState,
  })  : _resetSessionScopedState = resetSessionScopedState,
        _resetOrganizationScopedState = resetOrganizationScopedState;

  Future<void> clear() async {
    await AuthStorage.clearToken();
    await UserSession.clear();
    _resetSessionScopedState();
  }

  /// Cambia la sesión abierta por una nueva del mismo usuario. La organización de la cuenta viaja en el
  /// token, así que cuando cambia (el jugador aceptó una invitación) hay que renovarlo, y lo que había
  /// en caché era de la organización anterior.
  Future<void> replaceToken(String token) async {
    await AuthStorage.saveToken(token);
    await UserSession.loadFromToken(token);
    _resetOrganizationScopedState?.call();
  }
}
