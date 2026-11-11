/// Los valores fijos de la app. Cada uno se cambia solo aquí y se refleja en toda la app: nada de esto se escribe a mano
/// en otro archivo (tampoco en los diccionarios de traducción, que reciben los números con `{}`).
///
/// Se leen con `.value`, que ya trae su tipo: `AppConstants.listPageSize.value` es un `int`. Como `.value` no es una
/// constante de compilación, no sirve dentro de un `const` ni como valor por defecto de un parámetro.
enum AppConstants<T extends Object> {
  appName<String>('Sports Platform'),
  appVersion<String>('1.0.0'),

  // La política de contraseñas del backend (PasswordPolicy): si cambia allá, cambia aquí.
  minPasswordLength<int>(8),
  maxPasswordLength<int>(72),

  // Cuánto se descarga de una lista paginada del backend y cuánto se espera tras la última tecla antes de buscar.
  listPageSize<int>(20),
  searchDebounce<Duration>(Duration(milliseconds: 350)),

  // Lo máximo que se escribe de un código de equipo (con guion y espacios); el backend lo lee sin ellos.
  joinCodeMaxInputLength<int>(16),

  // Cuánto dura un partido por defecto, para el calendario cuando el backend no calculó su fin.
  defaultMatchDuration<Duration>(Duration(minutes: 90)),

  // Cuántos días, desde hoy, se pueden consultar en los horarios de una cancha y cuántos partidos próximos se listan.
  courtAgendaDays<int>(7),
  courtUpcomingMatchesLimit<int>(10),

  // Cuántos partidos, goleadores y resultados de la racha se muestran de un equipo dentro de un evento.
  teamMatchesPreviewLimit<int>(5),

  // La foto de perfil: lo más que pesa (el backend la rechaza con FILE_TOO_LARGE; `app.photos.max-bytes`), el lado más
  // largo y la calidad con que el selector de imágenes la reduce antes de enviarla.
  profilePhotoMaxMegabytes<int>(2),
  profilePhotoMaxSide<double>(1024),
  profilePhotoQuality<int>(85),

  // La edad más alta que puede tener una persona (`app.people.max-age-years` del backend: una fecha de nacimiento más
  // antigua se rechaza) y la edad con la que abre el selector de la fecha de nacimiento.
  maxPersonAgeYears<int>(120),
  birthDatePickerInitialAgeYears<int>(18);

  const AppConstants(this.value);

  final T value;

  /// El valor como texto, para rellenar el `{}` de una traducción: `'clave'.tr(args: [AppConstants.x.asText])`.
  String get asText => '$value';

  /// Lo más que puede pesar una foto de perfil, en bytes.
  static int get profilePhotoMaxBytes => profilePhotoMaxMegabytes.value * 1024 * 1024;
}
