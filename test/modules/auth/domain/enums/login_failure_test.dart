import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/auth/domain/enums/login_failure.dart';

import '../../../../support/real_translations.dart';

final _loginRequest = RequestOptions(path: '/users/auth/login');

DioException _refusedWith(int status, {Object? body}) => DioException(
  requestOptions: _loginRequest,
  type: DioExceptionType.badResponse,
  response: Response(requestOptions: _loginRequest, statusCode: status, data: body),
);

DioException _failedWith(DioExceptionType type) =>
    DioException(requestOptions: _loginRequest, type: type);

void main() {
  setUpAll(initRealTranslations);

  group('fromException', () {
    test('un 401 son credenciales incorrectas', () {
      expect(LoginFailure.fromException(_refusedWith(401)), LoginFailure.invalidCredentials);
    });

    test('un 403 se explica con el código que manda el backend', () {
      const codes = {
        'ADMIN_CANNOT_USE_MOBILE_APP': LoginFailure.administratorAccount,
        'ORGANIZATION_SUSPENDED': LoginFailure.organizationSuspended,
        'ORGANIZATION_NOT_FOUND': LoginFailure.organizationNotFound,
      };

      for (final entry in codes.entries) {
        final error = _refusedWith(403, body: {'success': false, 'status': 403, 'message': entry.key});
        expect(LoginFailure.fromException(error), entry.value, reason: entry.key);
      }
    });

    test('un 403 con un código que la app no conoce, o sin código, es acceso denegado', () {
      final unknownCode = _refusedWith(403, body: {'message': 'ADMIN_ACCESS_REQUIRED'});
      final withoutBody = _refusedWith(403);

      expect(LoginFailure.fromException(unknownCode), LoginFailure.accessDenied);
      expect(LoginFailure.fromException(withoutBody), LoginFailure.accessDenied);
    });

    test('sin respuesta del servidor por la red o el tiempo es falta de conexión', () {
      const connectionProblems = [
        DioExceptionType.connectionError,
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ];

      for (final type in connectionProblems) {
        expect(LoginFailure.fromException(_failedWith(type)), LoginFailure.noConnection, reason: '$type');
      }
    });

    test('cualquier otro fallo es inesperado', () {
      expect(LoginFailure.fromException(_refusedWith(500)), LoginFailure.unexpected);
      expect(LoginFailure.fromException(_failedWith(DioExceptionType.cancel)), LoginFailure.unexpected);
      expect(LoginFailure.fromException(StateError('sin token en la respuesta')), LoginFailure.unexpected);
    });
  });

  for (final locale in supportedTestLocales) {
    testWidgets('cada motivo se explica en ${locale.languageCode}', (tester) async {
      var unresolved = <String>[];

      await pumpWithRealTranslations(
        tester,
        locale: locale,
        home: (_) {
          unresolved = [
            for (final failure in LoginFailure.values)
              if (failure.translationKey.tr() == failure.translationKey) failure.translationKey,
          ];
          return const SizedBox.shrink();
        },
      );

      expect(unresolved, isEmpty, reason: 'sin traducción en ${locale.languageCode}');
    });
  }
}
