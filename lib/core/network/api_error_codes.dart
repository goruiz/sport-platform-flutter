import 'package:dio/dio.dart';

/// Lo que el backend dice cuando rechaza una petición, para que cada pantalla lo explique en el idioma del usuario.
///
/// El backend responde los motivos como **códigos estables**: en el `message` (un 400, 403 o 404 sin campo) o, si son de
/// un campo, en `data: {campo: CÓDIGO}`. Un 429 (demasiadas peticiones) llega sin código.
class ApiErrorCodes {
  /// Los códigos de la respuesta (el `message` y los valores de `data`); vacío si el error no trae respuesta.
  final Set<String> codes;

  /// El código HTTP de la respuesta; null si la petición no llegó al servidor.
  final int? statusCode;

  const ApiErrorCodes({required this.codes, required this.statusCode});

  /// Lee cualquier error: si no es de una petición, no trae códigos.
  factory ApiErrorCodes.of(Object error) {
    if (error is! DioException) return const ApiErrorCodes(codes: {}, statusCode: null);
    final body = error.response?.data;
    final codes = <String>{};
    if (body is Map<String, dynamic>) {
      final message = body['message'];
      if (message is String) codes.add(message);
      final data = body['data'];
      if (data is Map) {
        for (final reason in data.values) {
          if (reason is String) codes.add(reason);
        }
      }
    }
    return ApiErrorCodes(codes: codes, statusCode: error.response?.statusCode);
  }

  bool get isTooManyRequests => statusCode == 429;

  bool get isUnreachable => statusCode == null;

  /// El primer valor de [values] cuyo código dijo el backend; null si ninguno.
  T? firstOf<T extends Enum>(Iterable<T> values, String Function(T value) codeOf) {
    for (final value in values) {
      if (codes.contains(codeOf(value))) return value;
    }
    return null;
  }
}
