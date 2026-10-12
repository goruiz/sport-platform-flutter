import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:sport_platform/core/services/session_expired_listener.dart';
import 'api_endpoints.dart';
import 'auth_token_interceptor.dart';
import 'key_format_interceptor.dart';
import 'unauthorized_interceptor.dart';

class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.addAll([
      AuthTokenInterceptor(),
      UnauthorizedInterceptor(onSessionExpired: _notifySessionExpired),
      KeyFormatInterceptor(),
    ]);
  }

  // Se resuelve al recibir el 401 (no al construir el cliente) para no depender del orden de
  // arranque del DI. Usa GetIt.I y no el `getIt` de core/di para no crear un ciclo de imports
  // con los servicios que se registran allí.
  Future<void> _notifySessionExpired() =>
      GetIt.I<SessionExpiredListener>().onSessionExpired();

  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) =>
      _dio.get(path, queryParameters: queryParams);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      _dio.patch(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);
}
