import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/modules/users/data/datasource/user_profile_service.dart';
import 'package:sport_platform/modules/users/domain/entities/user_profile_update.dart';

/// Cliente que no sale a la red: guarda lo que se le envía y responde con [responseBody].
class _RecordingDioClient extends DioClient {
  final Map<String, dynamic> responseBody;
  String? sentPath;
  Map<String, dynamic>? sentData;

  _RecordingDioClient(this.responseBody);

  @override
  Future<Response> put(String path, {dynamic data}) async {
    sentPath = path;
    sentData = data as Map<String, dynamic>;
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: responseBody,
    );
  }
}

void main() {
  const apiResponse = {
    'success': true,
    'status': 200,
    'data': {
      'id': 'user-1',
      'firstName': 'Juan',
      'lastName': 'Pérez',
      'username': 'juanp',
      'email': 'juan@email.com',
    },
  };

  late _RecordingDioClient client;
  late UserProfileService service;

  setUp(() {
    client = _RecordingDioClient(apiResponse);
    service = UserProfileService(client: client);
  });

  group('UserProfileService.updateProfile', () {
    test('envía todos los campos cuando el usuario los completó', () async {
      await service.updateProfile(const UserProfileUpdate(
        firstName: 'Juan',
        middleName: 'Carlos',
        lastName: 'Pérez',
        secondLastName: 'Gómez',
        username: 'juanp',
      ));

      expect(client.sentPath, ApiEndpoints.updateProfile);
      expect(client.sentData, {
        'firstName': 'Juan',
        'middleName': 'Carlos',
        'lastName': 'Pérez',
        'secondLastName': 'Gómez',
        'username': 'juanp',
      });
    });

    test('omite los opcionales vacíos para no sobrescribirlos en el backend', () async {
      await service.updateProfile(const UserProfileUpdate(
        firstName: 'Juan',
        middleName: '',
        lastName: 'Pérez',
        secondLastName: null,
        username: 'juanp',
      ));

      expect(client.sentData, {
        'firstName': 'Juan',
        'lastName': 'Pérez',
        'username': 'juanp',
      });
    });

    test('devuelve el usuario que responde el backend', () async {
      final user = await service.updateProfile(const UserProfileUpdate(
        firstName: 'Juan',
        lastName: 'Pérez',
        username: 'juanp',
      ));

      expect(user.id, 'user-1');
      expect(user.username, 'juanp');
      expect(user.email, 'juan@email.com');
      expect(user.fullName, 'Juan Pérez');
    });
  });
}
