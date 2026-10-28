import 'package:dio/dio.dart';

/// Por qué no se pudo iniciar sesión. Un 403 trae en `message` el código del backend (`LoginError`) para que la
/// app explique el motivo en su idioma; el resto se distingue por el estado de la respuesta o por el tipo de fallo.
enum LoginFailure {
  /// El correo o la contraseña no son correctos (401).
  invalidCredentials('login.errors.invalid_credentials'),

  /// Las cuentas de administrador entran por el panel web, no por la app.
  administratorAccount(
    'login.errors.administrator_account',
    backendCode: 'ADMIN_CANNOT_USE_MOBILE_APP',
  ),

  /// La organización de la cuenta está suspendida.
  organizationSuspended(
    'login.errors.organization_suspended',
    backendCode: 'ORGANIZATION_SUSPENDED',
  ),

  /// La organización de la cuenta ya no existe.
  organizationNotFound(
    'login.errors.organization_not_found',
    backendCode: 'ORGANIZATION_NOT_FOUND',
  ),

  /// Otro 403: el backend rechazó la entrada con un motivo que esta versión de la app no conoce.
  accessDenied('login.errors.access_denied'),

  /// La petición no llegó al servidor: sin red o sin respuesta a tiempo.
  noConnection('login.errors.no_connection'),

  /// Cualquier otro fallo (un 500, una respuesta inesperada...).
  unexpected('login.errors.unexpected');

  const LoginFailure(this.translationKey, {this.backendCode});

  final String translationKey;

  /// El `message` que manda el backend en un 403 para este motivo.
  final String? backendCode;

  static const _connectionProblems = {
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError,
  };

  /// El motivo que explica el error de la petición de inicio de sesión.
  static LoginFailure fromException(Object error) {
    if (error is! DioException) return unexpected;

    return switch (error.response?.statusCode) {
      401 => invalidCredentials,
      403 => _fromBackendCode(error.response?.data) ?? accessDenied,
      null => _connectionProblems.contains(error.type) ? noConnection : unexpected,
      _ => unexpected,
    };
  }

  static LoginFailure? _fromBackendCode(Object? body) {
    final code = body is Map<String, dynamic> ? body['message'] : null;
    for (final failure in values) {
      if (failure.backendCode != null && failure.backendCode == code) return failure;
    }
    return null;
  }
}
