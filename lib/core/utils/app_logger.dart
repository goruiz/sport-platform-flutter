import 'dart:developer' as developer;

/// El registro de lo que falló y la app atrapó. Antes esos errores se descartaban con `catch (_) {}` y no quedaba rastro
/// de qué pasó ni por qué; ahora todos pasan por aquí, con el lugar donde ocurrió y la causa.
///
/// Escribe en el registro de desarrollo (la consola de `flutter run` y DevTools). Mandarlos a un servicio de reportes
/// (Sentry, Crashlytics) es cambiar solo [_write].
class AppLogger {
  AppLogger._();

  static const _loggerName = 'sport_platform';

  // Los niveles de `package:logging`: SEVERE y WARNING.
  static const _errorLevel = 1000;
  static const _warningLevel = 900;

  /// Algo falló y la persona lo nota: una pantalla que no cargó, una acción que no se hizo. [where] dice dónde, con el
  /// formato `Clase.método`.
  static void error(String where, Object error, StackTrace stackTrace) =>
      _write(_errorLevel, where, error, stackTrace);

  /// Algo falló y se tolera a propósito: la sesión se cierra aunque el servidor no responda, un dato extra que no llegó
  /// y la pantalla sigue sin él.
  static void warning(String where, Object error) => _write(_warningLevel, where, error, null);

  static void _write(int level, String where, Object error, StackTrace? stackTrace) {
    developer.log('$where falló', name: _loggerName, level: level, error: error, stackTrace: stackTrace);
  }
}
