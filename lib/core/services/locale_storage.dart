import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// El idioma que el usuario eligió, guardado para que la app abra en él la próxima vez. Sin una
/// elección guardada (o con una que ya no se soporta) abre en [defaultLocale].
class LocaleStorage {
  LocaleStorage._();

  static const _storageKey = 'app_locale';

  static const supportedLocales = [
    Locale('es'),
    Locale('en'),
    Locale('fr'),
    Locale('de'),
  ];
  static const defaultLocale = Locale('es');

  static Future<Locale> load() async {
    final prefs = await SharedPreferences.getInstance();
    return _supportedLocaleFor(prefs.getString(_storageKey)) ?? defaultLocale;
  }

  static Future<void> save(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, locale.languageCode);
  }

  static Locale? _supportedLocaleFor(String? languageCode) {
    for (final locale in supportedLocales) {
      if (locale.languageCode == languageCode) return locale;
    }
    return null;
  }
}
