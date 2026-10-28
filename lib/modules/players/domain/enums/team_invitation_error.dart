import 'package:dio/dio.dart';

/// Por qué el backend no dejó aceptar, rechazar o usar una invitación (`TeamInvitationError`). Llega como
/// el `message` de la respuesta de error, para que cada app lo explique en su idioma.
enum TeamInvitationError {
  /// Ya se aceptó, se rechazó o se usó para registrarse.
  notPending('NOT_PENDING'),

  /// Venció antes de que se respondiera.
  expired('EXPIRED'),

  /// El equipo que invitó ya no existe.
  teamNotFound('TEAM_NOT_FOUND'),

  /// El correo invitado no tiene un jugador que meter al equipo: primero hay que registrarse.
  playerNotFound('PLAYER_NOT_FOUND'),

  /// El enlace de registro no corresponde a ninguna invitación.
  invitationNotFound('INVITATION_NOT_FOUND');

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

  /// El texto en la bandeja de invitaciones, donde la persona ya tiene cuenta.
  String get translationKey => 'invitations.errors.$code';

  /// El texto en el registro con enlace, redactado para quien aún no tiene cuenta.
  String get registrationTranslationKey => switch (this) {
    notPending => 'invite_register.error_token_used',
    expired => 'invite_register.error_token_expired',
    invitationNotFound => 'invite_register.error_token_invalid',
    teamNotFound => translationKey,
    // Registrarse crea al jugador: este motivo solo existe al aceptar una invitación.
    playerNotFound => 'invite_register.error_generic',
  };
}
