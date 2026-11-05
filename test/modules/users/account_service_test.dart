import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/modules/users/data/datasource/account_service.dart';

/// Cliente que no sale a la red: guarda lo que se le envía y responde con [responseBody].
class _RecordingDioClient extends DioClient {
  final Map<String, dynamic> responseBody;
  final List<String> calls = [];
  Object? lastData;

  _RecordingDioClient(this.responseBody);

  Response _answer(String path) => Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: responseBody,
      );

  @override
  Future<Response> put(String path, {dynamic data}) async {
    calls.add('PUT $path');
    lastData = data;
    return _answer(path);
  }

  @override
  Future<Response> post(String path, {dynamic data}) async {
    calls.add('POST $path');
    lastData = data;
    return _answer(path);
  }

  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) async {
    calls.add('GET $path');
    return _answer(path);
  }
}

void main() {
  test('cambiar la contraseña envía la actual y la nueva con PUT', () async {
    final client = _RecordingDioClient({'success': true});

    await AccountService(client: client).changePassword(currentPassword: 'vieja123', newPassword: 'nueva1234');

    expect(client.calls, ['PUT ${ApiEndpoints.changePassword}']);
    expect(client.lastData, {'currentPassword': 'vieja123', 'newPassword': 'nueva1234'});
  });

  test('eliminar la cuenta envía la contraseña con POST (no DELETE: el cuerpo viaja)', () async {
    final client = _RecordingDioClient({'success': true});

    await AccountService(client: client).deleteAccount(password: 'secreta123');

    expect(client.calls, ['POST ${ApiEndpoints.deleteAccount}']);
    expect(client.lastData, {'password': 'secreta123'});
  });

  test('lee del backend si el correo ya está confirmado', () async {
    final confirmed = _RecordingDioClient({'data': {'emailVerified': true}});
    final pending = _RecordingDioClient({'data': {'emailVerified': false}});

    expect(await AccountService(client: confirmed).isEmailVerified(), isTrue);
    expect(await AccountService(client: pending).isEmailVerified(), isFalse);
    expect(confirmed.calls, ['GET ${ApiEndpoints.currentAccount}']);
  });

  test('un backend que no dice nada del correo no lo da por confirmado', () async {
    final client = _RecordingDioClient({'data': <String, dynamic>{}});

    expect(await AccountService(client: client).isEmailVerified(), isFalse);
  });

  test('reenviar el enlace y confirmar con el token llaman a sus endpoints', () async {
    final client = _RecordingDioClient({'success': true});
    final service = AccountService(client: client);

    await service.resendEmailVerification();
    await service.verifyEmail('token-del-correo');

    expect(client.calls, [
      'POST ${ApiEndpoints.resendEmailVerification}',
      'POST ${ApiEndpoints.verifyEmail}',
    ]);
    expect(client.lastData, {'token': 'token-del-correo'});
  });
}
