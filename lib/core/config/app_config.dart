import 'package:flutter/foundation.dart';

enum AppEnvironment { dev, staging, prod }

enum ApiKeyFormat { camelCase, snakeCase }

class AppConfig {
  static const String _env = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  // Permite apuntar la app a cualquier backend sin tocar código, p. ej. un dispositivo
  // físico por la red local:
  //   flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8080/api
  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');

  static const String _localBackendHost = 'localhost';
  // El emulador de Android no ve el localhost de la PC: la alcanza con esta IP especial.
  static const String _androidEmulatorHostOfPc = '10.0.2.2';
  static const String _localBackendPort = '8080';
  static const String _backendContextPath = '/api';

  static AppEnvironment get environment => switch (_env) {
        'staging' => AppEnvironment.staging,
        'prod' => AppEnvironment.prod,
        _ => AppEnvironment.dev,
      };

  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) return _baseUrlOverride;

    return switch (environment) {
      AppEnvironment.dev => _localBackendUrl,
      AppEnvironment.staging => 'https://staging-api.sports-platform.com/v1',
      AppEnvironment.prod => 'https://api.sports-platform.com/v1',
    };
  }

  static String get _localBackendUrl {
    final host = _isAndroidApp ? _androidEmulatorHostOfPc : _localBackendHost;
    return 'http://$host:$_localBackendPort$_backendContextPath';
  }

  // En web `defaultTargetPlatform` refleja el sistema del navegador, no que la app
  // sea de Android: ahí el backend local sí se alcanza por localhost.
  static bool get _isAndroidApp =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get isDev => environment == AppEnvironment.dev;
  static bool get isProd => environment == AppEnvironment.prod;

  // Formato de keys que devuelve el backend. Cambia aquí si el backend cambia.
  static const ApiKeyFormat apiKeyFormat = ApiKeyFormat.camelCase;
}
