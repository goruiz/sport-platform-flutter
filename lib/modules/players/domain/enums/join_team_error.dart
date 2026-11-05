import 'package:sport_platform/core/network/api_error_codes.dart';

/// Por qué el backend no dejó entrar al equipo con un código. Cada uno es el código estable que manda el backend
/// y la app lo explica en el idioma del usuario (`join_team.errors.<código>`).
enum JoinTeamError {
  /// Ningún equipo activo tiene ese código (mal escrito, cambiado o desactivado: se ven igual a propósito).
  codeNotFound('JOIN_CODE_NOT_FOUND'),

  /// Un jugador tiene un solo equipo: quien ya tiene uno no entra a otro con un código.
  alreadyInTeam('ALREADY_IN_TEAM'),

  /// Falta confirmar el correo de la cuenta.
  emailNotVerified('EMAIL_NOT_VERIFIED'),

  /// Demasiados intentos seguidos (no trae código: es el 429).
  tooManyRequests('TOO_MANY_REQUESTS');

  const JoinTeamError(this.code);

  final String code;

  /// El error que dice la respuesta de un fallo; null si es otro (sin conexión, un 500...).
  static JoinTeamError? fromException(Object error) {
    final reading = ApiErrorCodes.of(error);
    if (reading.isTooManyRequests) return tooManyRequests;
    return reading.firstOf(values, (error) => error.code);
  }

  String get translationKey => 'join_team.errors.$code';
}
