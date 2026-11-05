class AppConstants {
  static const String appName = 'Sports Platform';
  static const String appVersion = '1.0.0';

  // Credenciales con las que arranca el formulario de login.
  static const String fixedLoginEmail = 'el.bambucas@gmail.com';
  static const String fixedLoginPassword = 'el.bambucas@gmail.comA1';

  // La política de contraseñas del backend (PasswordPolicy): si cambia allá, cambia aquí.
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 72;

  // Cuánto se descarga de una lista paginada del backend y cuánto se espera tras la última tecla antes de buscar.
  static const int listPageSize = 20;
  static const Duration searchDebounce = Duration(milliseconds: 350);

  // Lo máximo que se escribe de un código de equipo (con guion y espacios); el backend lo lee sin ellos.
  static const int joinCodeMaxInputLength = 16;

  // Cuánto dura en el calendario un partido cuyo fin el backend no calculó.
  static const Duration defaultMatchDuration = Duration(minutes: 90);

  static final DateTime minPickerDate = DateTime(2020);
  static final DateTime maxPickerDate = DateTime(2035);
}
