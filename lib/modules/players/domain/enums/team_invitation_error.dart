import 'package:dio/dio.dart';

/// Por qué el backend no dejó aceptar o rechazar una invitación (`TeamInvitationError`). Llega como
/// el `message` de un 400, para que cada app lo explique en su idioma.
enum TeamInvitationError {
  /// Ya se aceptó o se rechazó.
  notPending('NOT_PENDING'),

  /// Venció antes de que se respondiera.
  expired('EXPIRED'),

  /// El equipo que invitó ya no existe.
  teamNotFound('TEAM_NOT_FOUND'),

  /// El correo invitado no tiene un jugador que meter al equipo: primero hay que registrarse.
  playerNotFound('PLAYER_NOT_FOUND');

  const TeamInvitationError(this.code);

  final String code;

  static TeamInvitationError? fromCode(String? code) {
    for (final error in values) {
      if (error.code == code) return error;
    }
    return null;
  }

  /// El error que dice la respuesta de un fallo del backend, o null si no es uno de estos.
  static TeamInvitationError? fromException(Object error) {
    if (error is! DioException) return null;
    final body = error.response?.data;
    final message = body is Map<String, dynamic> ? body['message'] : null;
    return fromCode(message?.toString());
  }

  String get translationKey => 'invitations.errors.$code';
}
