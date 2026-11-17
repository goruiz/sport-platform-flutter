import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_platform/core/utils/app_logger.dart';
import 'package:sport_platform/core/utils/birth_date_rules.dart';
import 'package:sport_platform/core/models/user_entity.dart';
import 'package:sport_platform/core/models/gender.dart';

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

    await update(entity);
  }

  /// Reemplaza el usuario en sesión (p. ej. tras editar su perfil) y lo guarda en disco.
  static Future<void> update(UserEntity user) async {
    _current = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_toMap(user)));
  }

  /// Completa el género y la fecha de nacimiento del usuario en sesión con los de su cuenta en el backend: el token con que
  /// se inició la sesión no los trae. Lo demás de la sesión se queda como estaba.
  static Future<void> mergePersonalData(UserEntity account) async {
    final user = _current;
    if (user == null) return;
    await update(user.withPersonalData(gender: account.gender, birthDate: account.birthDate));
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
    } catch (error, stackTrace) {
      AppLogger.error('UserSession.loadFromStorage', error, stackTrace);
    }
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

      final id = claims['id'] ?? claims['sub'];
      // Un token que no dice de quién es no sirve para armar la sesión.
      if (id == null) return null;

      return _fromMap({
        'id': id,
        'idRole': claims['idRole'] ?? claims['role'],
        'firstName': claims['firstName'],
        'middleName': claims['middleName'],
        'lastName': claims['lastName'],
        'secondLastName': claims['secondLastName'],
        'username': claims['username'],
        'email': claims['email'],
      });
    } catch (error, stackTrace) {
      AppLogger.error('UserSession._decodeToken', error, stackTrace);
      return null;
    }
  }

  static UserEntity _fromMap(Map<String, dynamic> m) {
    return UserEntity(
      id: m['id'] as String,
      idRole: m['idRole'] as String?,
      firstName: m['firstName'] as String?,
      middleName: m['middleName'] as String?,
      lastName: m['lastName'] as String?,
      secondLastName: m['secondLastName'] as String?,
      username: m['username'] as String?,
      email: m['email'] as String?,
      gender: Gender.fromApi(m['gender'] as String?),
      birthDate: parseBirthDate(m['birthDate']),
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
        'gender': e.gender?.apiValue,
        'birthDate': e.birthDate == null ? null : formatBirthDateForApi(e.birthDate!),
      };
}
