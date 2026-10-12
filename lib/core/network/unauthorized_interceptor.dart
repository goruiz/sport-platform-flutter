import 'package:dio/dio.dart';
import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/auth_token_interceptor.dart';

/// Detecta que el backend rechazó el token de la sesión (401) y avisa para cerrarla.
///
/// Solo cuenta si la petición llevaba token: un 401 en un endpoint público no significa que
/// la sesión haya vencido. Y aunque lo lleve, no cuenta en el login (son credenciales
/// incorrectas, aunque haya un token viejo guardado) ni en el logout (ya cierra la sesión).
class UnauthorizedInterceptor extends Interceptor {
  static const int _unauthorizedStatusCode = 401;
  static final Set<String> _endpointsExemptFromSessionExpiry = {
    ApiEndpoints.login,
    ApiEndpoints.logout,
  };

  final Future<void> Function() onSessionExpired;

  UnauthorizedInterceptor({required this.onSessionExpired});

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      if (_isSessionExpired(err)) await onSessionExpired();
    } finally {
      // El error original siempre sigue su camino: quien hizo la petición decide qué mostrar.
      handler.next(err);
    }
  }

  bool _isSessionExpired(DioException err) =>
      err.response?.statusCode == _unauthorizedStatusCode &&
      _carriedSessionToken(err.requestOptions) &&
      !_endpointsExemptFromSessionExpiry.contains(err.requestOptions.path);

  bool _carriedSessionToken(RequestOptions request) =>
      request.headers.containsKey(AuthTokenInterceptor.authorizationHeader);
}
