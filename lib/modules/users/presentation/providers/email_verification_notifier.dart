import 'package:flutter/foundation.dart';
import 'package:sport_platform/modules/users/data/datasource/account_service.dart';
import 'package:sport_platform/modules/users/domain/enums/account_error.dart';

/// Si el correo de la cuenta ya fue confirmado. Lo comparten el aviso del inicio y el enlace que llega por correo, por eso
/// vive en GetIt y se reinicia al cerrar la sesión.
///
/// Mientras no esté confirmado, el jugador no puede unirse a equipos (ni aceptando una invitación ni con un código).
class EmailVerificationNotifier extends ChangeNotifier {
  static const _genericErrorKey = 'account.errors.generic';

  final AccountService _service;

  /// Null mientras no se sabe: sin respuesta del backend no se avisa de nada que no se pueda asegurar.
  bool? _verified;

  EmailVerificationNotifier(this._service);

  bool get needsVerification => _verified == false;

  Future<void> load() async {
    try {
      _verified = await _service.isEmailVerified();
    } catch (_) {
      // Sin conexión se deja lo que se sabía: el aviso no es lo bastante importante para un error.
    }
    notifyListeners();
  }

  /// Pide otro enlace. Devuelve la clave de traducción de lo que hay que decirle al usuario.
  Future<String> resend() async {
    try {
      await _service.resendEmailVerification();
      return 'verify_email.resent';
    } catch (error) {
      return AccountError.fromException(error)?.translationKey ?? _genericErrorKey;
    }
  }

  /// El usuario dice que ya lo confirmó (quizá en el navegador): se vuelve a leer del backend.
  Future<String> checkAgain() async {
    await load();
    return _verified == true ? 'verify_email.confirmed' : 'verify_email.still_pending';
  }

  /// Confirma el correo con el token del enlace que se abrió en la app.
  Future<String> confirmWithToken(String token) async {
    try {
      await _service.verifyEmail(token);
      await load();
      return 'verify_email.confirmed';
    } catch (error) {
      return AccountError.fromException(error)?.translationKey ?? _genericErrorKey;
    }
  }

  /// Olvida lo del usuario anterior (al cerrar la sesión).
  void clear() {
    _verified = null;
    notifyListeners();
  }
}
