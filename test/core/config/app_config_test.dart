import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/core/config/app_config.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  group('AppConfig.baseUrl en el entorno dev', () {
    test('en Android alcanza la PC por el alias del emulador', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      expect(AppConfig.baseUrl, 'http://10.0.2.2:8080/api');
    });

    test('en otras plataformas usa localhost', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      expect(AppConfig.baseUrl, 'http://localhost:8080/api');
    });
  });
}
