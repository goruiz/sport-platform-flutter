import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const _tokenKey = 'auth_token';
  static String? _cache;

  static Future<void> saveToken(String token) async {
    _cache = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// El token que ya está en memoria, sin esperar al disco; null si aún no se leyó. Sirve donde no se puede esperar,
  /// como las cabeceras de una imagen de la red.
  static String? get cachedToken => _cache;

  static Future<String?> getToken() async {
    if (_cache != null) return _cache;
    final prefs = await SharedPreferences.getInstance();
    _cache = prefs.getString(_tokenKey);
    return _cache;
  }

  static Future<void> clearToken() async {
    _cache = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
