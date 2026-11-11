import 'package:flutter/foundation.dart';
import 'package:sport_platform/modules/users/data/datasource/account_service.dart';
import 'package:sport_platform/modules/users/domain/enums/account_capability.dart';

/// Lo extra que el rol de la cuenta le permite hacer (ver [AccountCapability]). Lo comparten todas las pantallas que
/// ofrecen una acción así, por eso vive en GetIt: se lee una vez por sesión y se reinicia al cerrarla.
///
/// Sin respuesta del backend (sin conexión) no se ofrece nada que no se pueda asegurar: [can] dice que no.
class AccountCapabilitiesNotifier extends ChangeNotifier {
  final AccountService _service;

  AccountCapabilitiesNotifier(this._service);

  /// Null mientras no se sabe.
  Set<AccountCapability>? _capabilities;

  /// Las lecturas en curso comparten una sola petición.
  Future<Set<AccountCapability>>? _loading;

  bool can(AccountCapability capability) => _capabilities?.contains(capability) ?? false;

  /// Lo que la cuenta puede hacer: lo ya leído, o lo lee si todavía no se sabe. Una lectura fallida no se recuerda: la
  /// próxima pantalla lo intenta de nuevo.
  Future<Set<AccountCapability>> ensureLoaded() {
    final known = _capabilities;
    if (known != null) return Future.value(known);
    return _loading ??= _read();
  }

  /// Vuelve a leerlas (el administrador pudo cambiar el rol de la cuenta). Si falla, deja lo que se sabía.
  Future<void> refresh() async {
    await (_loading = _read());
  }

  /// Olvida lo de la cuenta anterior (al cerrar la sesión).
  void clear() {
    _capabilities = null;
    _loading = null;
    notifyListeners();
  }

  Future<Set<AccountCapability>> _read() async {
    try {
      final capabilities = await _service.loadCapabilities();
      _capabilities = capabilities;
      notifyListeners();
      return capabilities;
    } catch (_) {
      return _capabilities ?? const {};
    } finally {
      _loading = null;
    }
  }
}
