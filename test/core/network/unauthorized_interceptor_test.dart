import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/auth_token_interceptor.dart';
import 'package:sport_platform/core/network/unauthorized_interceptor.dart';

/// Responde siempre con el mismo código HTTP, sin tocar la red.
class _FixedStatusAdapter implements HttpClientAdapter {
  final int statusCode;

  _FixedStatusAdapter(this.statusCode);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString('{}', statusCode, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      });

  @override
  void close({bool force = false}) {}
}

void main() {
  const tokenHeader = {AuthTokenInterceptor.authorizationHeader: 'Bearer token'};

  late int sessionExpiredCalls;

  Dio buildDio(int responseStatusCode) {
    sessionExpiredCalls = 0;
    return Dio(BaseOptions(baseUrl: 'http://test'))
      ..httpClientAdapter = _FixedStatusAdapter(responseStatusCode)
      ..interceptors.add(
        UnauthorizedInterceptor(onSessionExpired: () async => sessionExpiredCalls++),
      );
  }

  group('UnauthorizedInterceptor', () {
    test('avisa cuando el backend responde 401 a una petición con token', () async {
      final dio = buildDio(401);

      await expectLater(
        dio.get('/events', options: Options(headers: tokenHeader)),
        throwsA(isA<DioException>()),
      );

      expect(sessionExpiredCalls, 1);
    });

    test('no avisa si la petición no llevaba token (p. ej. credenciales incorrectas)', () async {
      final dio = buildDio(401);

      await expectLater(dio.post(ApiEndpoints.login), throwsA(isA<DioException>()));

      expect(sessionExpiredCalls, 0);
    });

    test('no avisa ante errores que no son 401', () async {
      for (final status in [403, 404, 500]) {
        final dio = buildDio(status);

        await expectLater(
          dio.get('/events', options: Options(headers: tokenHeader)),
          throwsA(isA<DioException>()),
        );

        expect(sessionExpiredCalls, 0, reason: 'status $status');
      }
    });

    test('no avisa en el login ni en el logout, aunque lleven un token', () async {
      for (final endpoint in [ApiEndpoints.login, ApiEndpoints.logout]) {
        final dio = buildDio(401);

        await expectLater(
          dio.post(endpoint, options: Options(headers: tokenHeader)),
          throwsA(isA<DioException>()),
        );

        expect(sessionExpiredCalls, 0, reason: endpoint);
      }
    });
  });
}
