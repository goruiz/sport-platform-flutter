import 'package:shared_preferences/shared_preferences.dart';

/// El equipo que el jugador eligió ver, guardado para que la app abra en él la próxima vez (como `LocaleStorage` con el
/// idioma). Sin una elección guardada, o con un equipo que ya no es suyo, la app abre en el último al que entró.
class ActiveTeamStorage {
  ActiveTeamStorage._();

  static const _storageKey = 'active_team_id';

  static Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_storageKey);
  }

  static Future<void> save(String teamId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, teamId);
  }

  /// Al cerrar la sesión: el equipo de un usuario no debe quedarle elegido al siguiente que inicie sesión.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
