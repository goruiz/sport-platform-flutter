import 'package:dio/dio.dart';
import 'package:sport_platform/core/services/auth_storage.dart';

/// Adjunta el token de la sesión a cada petición, si hay uno guardado.
class AuthTokenInterceptor extends Interceptor {
  static const String authorizationHeader = 'Authorization';
  static const String _bearerScheme = 'Bearer';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await AuthStorage.getToken();
    if (token != null) {
      options.headers[authorizationHeader] = '$_bearerScheme $token';
    }
    handler.next(options);
  }
}
