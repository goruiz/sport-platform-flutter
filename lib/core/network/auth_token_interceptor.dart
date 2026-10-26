import 'package:dio/dio.dart';
import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/services/auth_storage.dart';

/// Adjunta el token de la sesión a cada petición, si hay uno guardado.
class AuthTokenInterceptor extends Interceptor {
  static const String authorizationHeader = 'Authorization';
  static const String _bearerScheme = 'Bearer';
  static const Set<String> _publicAuthEndpoints = {
    ApiEndpoints.login,
    ApiEndpoints.register,
    ApiEndpoints.forgotPassword,
    ApiEndpoints.resetPassword,
  };

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_publicAuthEndpoints.contains(options.path)) {
      handler.next(options);
      return;
    }
    final token = await AuthStorage.getToken();
    if (token != null) {
      options.headers[authorizationHeader] = '$_bearerScheme $token';
    }
    handler.next(options);
  }
}
