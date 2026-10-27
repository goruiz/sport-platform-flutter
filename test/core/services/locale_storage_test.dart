import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_platform/core/services/locale_storage.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('sin una elección guardada abre en español', () async {
    expect(await LocaleStorage.load(), const Locale('es'));
  });

  test('recuerda el idioma que el usuario eligió', () async {
    await LocaleStorage.save(const Locale('fr'));

    expect(await LocaleStorage.load(), const Locale('fr'));
  });

  test('un idioma guardado que ya no se soporta vuelve al español', () async {
    SharedPreferences.setMockInitialValues({'app_locale': 'pt'});

    expect(await LocaleStorage.load(), LocaleStorage.defaultLocale);
  });

  test('el idioma por defecto es uno de los soportados', () {
    expect(
      LocaleStorage.supportedLocales,
      contains(LocaleStorage.defaultLocale),
    );
  });
}
