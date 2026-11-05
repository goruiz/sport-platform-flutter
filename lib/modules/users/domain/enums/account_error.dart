import 'package:sport_platform/core/network/api_error_codes.dart';

/// Por qué el backend no dejó cambiar la contraseña, confirmar el correo o eliminar la cuenta. Cada uno es el código
/// estable que manda el backend, y la app lo explica en el idioma del usuario (`account.errors.<código>`).
enum AccountError {
  /// La contraseña actual que se escribió no es la de la cuenta.
  incorrectCurrentPassword('INCORRECT_CURRENT_PASSWORD'),

  /// La contraseña nueva es igual a la actual.
  newPasswordSameAsCurrent('NEW_PASSWORD_SAME_AS_CURRENT'),

  /// La contraseña con que se confirmó la eliminación no es la de la cuenta.
  incorrectPassword('INCORRECT_PASSWORD'),

  /// Las cuentas de administrador no se eliminan desde la app.
  staffAccount('STAFF_ACCOUNT'),

  /// El enlace del correo ya se usó, venció o no existe.
  invalidOrExpiredLink('INVALID_OR_EXPIRED'),

  /// Demasiadas peticiones seguidas (no trae código: es el 429).
  tooManyRequests('TOO_MANY_REQUESTS');

  const AccountError(this.code);

  final String code;

  /// El error que dice la respuesta de un fallo; null si es otro (sin conexión, un 500...).
  static AccountError? fromException(Object error) {
    final reading = ApiErrorCodes.of(error);
    if (reading.isTooManyRequests) return tooManyRequests;
    return reading.firstOf(values, (error) => error.code);
  }

  String get translationKey => 'account.errors.$code';
}
