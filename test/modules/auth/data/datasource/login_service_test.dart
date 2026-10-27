import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/services/auth_storage.dart';
import 'package:sport_platform/core/services/user_session.dart';
import 'package:sport_platform/modules/auth/data/datasource/login_service.dart';

/// Cliente que no sale a la red: guarda lo que se le envía y responde con [responseBody]
/// (o rechaza la petición si [rejectWith] tiene un código).
class _RecordingDioClient extends DioClient {
  final Map<String, dynamic> responseBody;
  final int? rejectWith;
  String? sentPath;
  Map<String, dynamic>? sentData;

  _RecordingDioClient(this.responseBody, {this.rejectWith});

  @override
  Future<Response> post(String path, {dynamic data}) async {
    sentPath = path;
    sentData = data as Map<String, dynamic>;
    final requestOptions = RequestOptions(path: path);
    final response = Response(
      requestOptions: requestOptions,
      statusCode: rejectWith ?? 200,
      data: responseBody,
    );
    if (rejectWith != null) {
      throw DioException(
        requestOptions: requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    }
    return response;
  }
}

// JWT sin firma verificable: el payload es {"id":"user-1","email":"juan@email.com"}.
const _token =
    'eyJhbGciOiJIUzI1NiJ9.eyJpZCI6InVzZXItMSIsImVtYWlsIjoianVhbkBlbWFpbC5jb20ifQ.firma';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('envía las credenciales como usuario de la app y guarda el token y la sesión', () async {
    final client = _RecordingDioClient({
      'success': true,
      'status': 200,
      'data': {'token': _token},
    });
    final service = LoginService(client: client);

    await service.signIn(email: 'juan@email.com', password: 'password123');

    expect(client.sentPath, ApiEndpoints.login);
    expect(client.sentData, {
      'email': 'juan@email.com',
      'password': 'password123',
      'clientType': 'MOBILE_APP',
    });
    expect(await AuthStorage.hasToken(), isTrue);
    expect(UserSession.current?.id, 'user-1');
  });

  test('si el backend rechaza las credenciales lanza la excepción y no guarda nada', () async {
    await AuthStorage.clearToken();
    await UserSession.clear();
    final client = _RecordingDioClient(
      {'success': false, 'status': 401},
      rejectWith: 401,
    );
    final service = LoginService(client: client);

    await expectLater(
      service.signIn(email: 'juan@email.com', password: 'incorrecta'),
      throwsA(isA<DioException>()),
    );

    expect(await AuthStorage.hasToken(), isFalse);
    expect(UserSession.current, isNull);
  });
}
