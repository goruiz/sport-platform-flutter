import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/core/network/api_error_codes.dart';
import 'package:sport_platform/modules/players/domain/enums/join_team_error.dart';
import 'package:sport_platform/modules/users/domain/enums/account_error.dart';

DioException _failure(int status, Object? body) {
  final request = RequestOptions(path: '/x');
  return DioException(
    requestOptions: request,
    response: Response(requestOptions: request, statusCode: status, data: body),
    type: DioExceptionType.badResponse,
  );
}

void main() {
  group('ApiErrorCodes', () {
    test('lee el código del message', () {
      final reading = ApiErrorCodes.of(_failure(404, {'success': false, 'message': 'JOIN_CODE_NOT_FOUND'}));

      expect(reading.codes, {'JOIN_CODE_NOT_FOUND'});
      expect(reading.statusCode, 404);
    });

    test('lee los códigos de los campos de data', () {
      final reading = ApiErrorCodes.of(_failure(400, {
        'message': 'Validation Failed',
        'data': {'password': 'INCORRECT_PASSWORD'},
      }));

      expect(reading.codes, containsAll(['INCORRECT_PASSWORD', 'Validation Failed']));
    });

    test('un error que no es de una petición no trae códigos ni estado', () {
      final reading = ApiErrorCodes.of(Exception('sin red'));

      expect(reading.codes, isEmpty);
      expect(reading.isUnreachable, isTrue);
    });

    test('un cuerpo que no es un mapa no rompe la lectura', () {
      final reading = ApiErrorCodes.of(_failure(500, '<html>error</html>'));

      expect(reading.codes, isEmpty);
      expect(reading.statusCode, 500);
    });

    test('el 429 es «demasiadas peticiones»', () {
      expect(ApiErrorCodes.of(_failure(429, {'message': 'Too many requests'})).isTooManyRequests, isTrue);
    });
  });

  group('AccountError', () {
    test('reconoce el motivo de un campo (la contraseña actual incorrecta)', () {
      final error = _failure(400, {'data': {'currentPassword': 'INCORRECT_CURRENT_PASSWORD'}});

      expect(AccountError.fromException(error), AccountError.incorrectCurrentPassword);
    });

    test('reconoce el de eliminar la cuenta, en el campo o en el message', () {
      expect(
        AccountError.fromException(_failure(400, {'data': {'password': 'INCORRECT_PASSWORD'}})),
        AccountError.incorrectPassword,
      );
      expect(
        AccountError.fromException(_failure(400, {'message': 'STAFF_ACCOUNT'})),
        AccountError.staffAccount,
      );
    });

    test('un enlace de confirmación vencido', () {
      expect(
        AccountError.fromException(_failure(400, {'data': {'token': 'INVALID_OR_EXPIRED'}})),
        AccountError.invalidOrExpiredLink,
      );
    });

    test('un 429 sin código es demasiados intentos', () {
      expect(AccountError.fromException(_failure(429, {'message': 'x'})), AccountError.tooManyRequests);
    });

    test('un error desconocido no se inventa un motivo', () {
      expect(AccountError.fromException(_failure(500, {'message': 'boom'})), isNull);
      expect(AccountError.fromException(Exception('sin red')), isNull);
    });

    test('cada motivo apunta a su clave de traducción', () {
      expect(AccountError.incorrectPassword.translationKey, 'account.errors.INCORRECT_PASSWORD');
    });
  });

  group('JoinTeamError', () {
    test('reconoce los tres motivos del backend', () {
      expect(JoinTeamError.fromException(_failure(404, {'message': 'JOIN_CODE_NOT_FOUND'})), JoinTeamError.codeNotFound);
      expect(JoinTeamError.fromException(_failure(400, {'message': 'ALREADY_IN_TEAM'})), JoinTeamError.alreadyInTeam);
      expect(JoinTeamError.fromException(_failure(403, {'message': 'EMAIL_NOT_VERIFIED'})), JoinTeamError.emailNotVerified);
    });

    test('un 429 es demasiados intentos y lo demás no tiene motivo', () {
      expect(JoinTeamError.fromException(_failure(429, null)), JoinTeamError.tooManyRequests);
      expect(JoinTeamError.fromException(_failure(500, {'message': 'boom'})), isNull);
    });

    test('la clave de traducción lleva el código', () {
      expect(JoinTeamError.codeNotFound.translationKey, 'join_team.errors.JOIN_CODE_NOT_FOUND');
    });
  });
}
