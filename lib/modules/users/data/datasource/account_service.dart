import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/network/response_parser.dart';

/// Lo que la persona hace con su propia cuenta: contraseña, correo y eliminarla. Los rechazos del backend llegan como
/// excepción de la petición; `AccountError.fromException` dice cuál fue.
class AccountService {
  final DioClient _client;

  AccountService({DioClient? client}) : _client = client ?? DioClient();

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.put(
      ApiEndpoints.changePassword,
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  /// Borra la cuenta y sus datos personales. Pide la contraseña porque no se puede deshacer.
  Future<void> deleteAccount({required String password}) async {
    await _client.post(ApiEndpoints.deleteAccount, data: {'password': password});
  }

  /// Si el dueño del correo ya lo confirmó. Se lee del backend (no del token): el token guarda lo que era al iniciar.
  Future<bool> isEmailVerified() async {
    final response = await _client.get(ApiEndpoints.currentAccount);
    return ResponseParser.toMap(response.data)['emailVerified'] == true;
  }

  Future<void> resendEmailVerification() async {
    await _client.post(ApiEndpoints.resendEmailVerification);
  }

  /// Confirma el correo con el token del enlace que llegó por email.
  Future<void> verifyEmail(String token) async {
    await _client.post(ApiEndpoints.verifyEmail, data: {'token': token});
  }
}
