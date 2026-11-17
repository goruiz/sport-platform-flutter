/// El género de una persona (`Gender` del backend): lo que se pide al completar el perfil y al registrarse, y lo que una
/// categoría de equipo puede exigir. El backend lo guarda como texto, así que [apiValue] es lo que se envía y se recibe.
enum Gender {
  male('MALE'),
  female('FEMALE');

  const Gender(this.apiValue);

  final String apiValue;

  /// Null si el valor no es uno de estos (un backend más nuevo, o una cuenta que aún no lo dijo).
  static Gender? fromApi(String? value) {
    for (final gender in values) {
      if (gender.apiValue == value) return gender;
    }
    return null;
  }

  String get translationKey => 'profile.gender_options.$apiValue';
}
