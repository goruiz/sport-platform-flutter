enum AppEnvironment { dev, staging, prod }

class AppConfig {
  static const String _env = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static AppEnvironment get environment => switch (_env) {
        'staging' => AppEnvironment.staging,
        'prod' => AppEnvironment.prod,
        _ => AppEnvironment.dev,
      };

  static String get baseUrl => switch (environment) {
        AppEnvironment.dev =>
          'http://localhost:8080/api',
        AppEnvironment.staging =>
          'https://staging-api.sports-platform.com/v1',
        AppEnvironment.prod =>
          'https://api.sports-platform.com/v1',
      };

  static bool get isDev => environment == AppEnvironment.dev;
  static bool get isProd => environment == AppEnvironment.prod;
}
