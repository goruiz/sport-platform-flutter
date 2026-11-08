/// Los valores fijos de la app. Cada uno se cambia solo aquí y se refleja en toda la app: nada de esto se escribe a mano
/// en otro archivo (tampoco en los diccionarios de traducción, que reciben los números con `{}`).
///
/// Se leen con `.value`, que ya trae su tipo: `AppConstants.listPageSize.value` es un `int`. Como `.value` no es una
/// constante de compilación, no sirve dentro de un `const` ni como valor por defecto de un parámetro.
enum AppConstants<T extends Object> {
  appName<String>('Sports Platform'),
  appVersion<String>('1.0.0'),

  // Credenciales con las que arranca el formulario de login.
  fixedLoginEmail<String>('el.bambucas@gmail.com'),
  fixedLoginPassword<String>('el.bambucas@gmail.comA1'),

  // La política de contraseñas del backend (PasswordPolicy): si cambia allá, cambia aquí.
  minPasswordLength<int>(8),
  maxPasswordLength<int>(72),

  // Cuánto se descarga de una lista paginada del backend y cuánto se espera tras la última tecla antes de buscar.
  listPageSize<int>(20),
  searchDebounce<Duration>(Duration(milliseconds: 350)),

  // Lo máximo que se escribe de un código de equipo (con guion y espacios); el backend lo lee sin ellos.
  joinCodeMaxInputLength<int>(16),

  // Cuánto dura un partido por defecto: en el calendario cuando el backend no calculó su fin, y en el calendario automático.
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

  // Años entre los que se elige una fecha (ver `minPickerDate` y `maxPickerDate`).
  minPickerYear<int>(2020),
  maxPickerYear<int>(2035);

  const AppConstants(this.value);

  final T value;

  /// El valor como texto, para rellenar el `{}` de una traducción: `'clave'.tr(args: [AppConstants.x.asText])`.
  String get asText => '$value';

  /// Lo más que puede pesar una foto de perfil, en bytes.
  static int get profilePhotoMaxBytes => profilePhotoMaxMegabytes.value * 1024 * 1024;

  /// Primer y último día que ofrecen los selectores de fecha. `DateTime` no es constante, por eso se guardan los años.
  static DateTime get minPickerDate => DateTime(minPickerYear.value);
  static DateTime get maxPickerDate => DateTime(maxPickerYear.value);
}
