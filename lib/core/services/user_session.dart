import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_platform/modules/users/domain/entities/user_entity.dart';

/// Singleton que mantiene la sesión del usuario autenticado en memoria.
///
/// Ciclo de vida:
///   Login  → UserSession.loadFromToken(token)
///   Inicio → UserSession.loadFromStorage()
///   Logout → UserSession.clear()
///
/// Uso en cualquier widget:
///   final user = UserSession.current;
class UserSession {
  static const _storageKey = 'user_session';

  static UserEntity? _current;

  static UserEntity? get current => _current;

  static bool get isAuthenticated => _current != null;

  /// Decodifica el payload del JWT y guarda el usuario en memoria + disco.
  /// Llamar justo después de guardar el token en AuthStorage.
  static Future<void> loadFromToken(String token) async {
    final entity = _decodeToken(token);
    if (entity == null) return;

    _current = entity;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_toMap(entity)));
  }

  /// Recupera el usuario desde disco al arrancar la app (cold start).
  /// No hace nada si ya hay un usuario en memoria.
  static Future<void> loadFromStorage() async {
    if (_current != null) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _current = _fromMap(map);
    } catch (_) {}
  }

  /// Limpia la sesión de memoria y disco.
  /// Llamar en el logout junto a AuthStorage.clearToken().
  static Future<void> clear() async {
    _current = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  // ---------------------------------------------------------------------------

  static UserEntity? _decodeToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // JWT usa base64url sin padding — lo normalizamos antes de decodificar
      var payload = parts[1];
      final rem = payload.length % 4;
      if (rem != 0) payload += '=' * (4 - rem);

      final decoded = utf8.decode(base64Url.decode(payload));
      final claims = jsonDecode(decoded) as Map<String, dynamic>;

      return _fromMap({
        'id':  claims['id'] ?? claims['sub'] ?? '',
        'idRole': claims['idRole'] ?? claims['role'],
        'firstName': claims['firstName'],
        'middleName': claims['middleName'],
        'lastName': claims['lastName'],
        'secondLastName': claims['secondLastName'],
        'username': claims['username'],
        'email': claims['email'],
      });
    } catch (_) {
      return null;
    }
  }

  static UserEntity _fromMap(Map<String, dynamic> m) {
    return UserEntity(
      id: m['id'] as String? ?? '',
      idRole: m['idRole'] as String?,
      firstName: m['firstName'] as String?,
      middleName: m['middleName'] as String?,
      lastName: m['lastName'] as String?,
      secondLastName: m['secondLastName'] as String?,
      username: m['username'] as String?,
      email: m['email'] as String?,
    );
  }

  static Map<String, dynamic> _toMap(UserEntity e) => {
        'id': e.id,
        'idRole': e.idRole,
        'firstName': e.firstName,
        'middleName': e.middleName,
        'lastName': e.lastName,
        'secondLastName': e.secondLastName,
        'username': e.username,
        'email': e.email,
      };
}
