import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/network/response_parser.dart';
import 'package:sport_platform/core/services/auth_storage.dart';
import 'package:sport_platform/core/services/user_session.dart';

/// Inicia sesión como usuario de la app y deja guardada la sesión.
///
/// Lo usan el login y el registro por invitación (que entra solo al terminar de crear la cuenta).
class LoginService {
  // El backend rechaza a los administradores en la app: es lo que separa los dos clientes.
  static const String _mobileAppClientType = 'MOBILE_APP';

  final DioClient _client;

  LoginService({DioClient? client}) : _client = client ?? DioClient();

  /// Lanza la excepción de la petición si el backend rechaza las credenciales.
  Future<void> signIn({required String email, required String password}) async {
    final response = await _client.post(
      ApiEndpoints.login,
      data: {
        'email': email,
        'password': password,
        'clientType': _mobileAppClientType,
      },
    );
    final token = ResponseParser.toMap(response.data)['token'] as String;
    await AuthStorage.saveToken(token);
    await UserSession.loadFromToken(token);
  }
}
