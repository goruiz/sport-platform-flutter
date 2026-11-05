import 'package:flutter/widgets.dart';

/// Los idiomas de la app, con el nombre en su propio idioma y su bandera. Deben coincidir con
/// `LocaleStorage.supportedLocales` y con los archivos de `assets/translations`.
enum AppLanguage {
  spanish('es', 'Español', '🇪🇸'),
  english('en', 'English', '🇬🇧'),
  french('fr', 'Français', '🇫🇷'),
  german('de', 'Deutsch', '🇩🇪');

  final String code;
  final String nativeName;
  final String flag;

  const AppLanguage(this.code, this.nativeName, this.flag);

  Locale get locale => Locale(code);

  /// El idioma de un código; uno desconocido cae en español, el idioma por defecto.
  static AppLanguage fromCode(String code) {
    for (final language in values) {
      if (language.code == code) return language;
    }
    return AppLanguage.spanish;
  }
}
