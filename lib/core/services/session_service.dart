import 'package:sport_platform/core/services/auth_storage.dart';
import 'package:sport_platform/core/services/user_session.dart';

/// Cierra la sesión local: credenciales, usuario y estado en memoria del usuario anterior.
///
/// Lo usan el logout manual y la expiración de sesión, para que ambos dejen la app igual.
class SessionService {
  final void Function() _resetSessionScopedState;

  /// [resetSessionScopedState] descarta el estado en memoria que pertenece al usuario
  /// (cachés, listas) para que no se le muestre al siguiente que inicie sesión.
  SessionService({required void Function() resetSessionScopedState})
      : _resetSessionScopedState = resetSessionScopedState;

  Future<void> clear() async {
    await AuthStorage.clearToken();
    await UserSession.clear();
    _resetSessionScopedState();
  }
}
