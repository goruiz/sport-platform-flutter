import 'package:sport_platform/core/constants/app_constants.dart';

// Reglas de la fecha de nacimiento. Funciones puras: las usan el formulario de perfil y el registro por invitación.
//
// El backend rechaza una fecha futura o de alguien de más de `app.people.max-age-years` años (INVALID_BIRTH_DATE);
// se revisa aquí antes de enviarla para explicarlo junto al campo y sin esperar a la red. Lo que una categoría de
// equipo exige de la edad lo decide el backend (la edad cambia cada día): la app nunca la calcula para decidir
// quién puede jugar.

/// Por qué una fecha de nacimiento no sirve.
enum BirthDateIssue {
  empty,
  inTheFuture,
  tooOld;

  /// La clave de traducción del motivo. Que esté vacía lo dice cada pantalla con su propio texto («Requerido»).
  String? get translationKey => switch (this) {
    BirthDateIssue.empty => null,
    BirthDateIssue.inTheFuture => 'profile.birth_date_future',
    BirthDateIssue.tooOld => 'profile.birth_date_too_old',
  };
}

/// Solo el día: la hora no cuenta en una fecha de nacimiento.
DateTime dateOnly(DateTime moment) => DateTime(moment.year, moment.month, moment.day);

/// La fecha más antigua que se acepta: la de hoy hace [AppConstants.maxPersonAgeYears] años. Es un poco más estricta que la
/// del backend (que cuenta años cumplidos), a favor de no enviar lo que se sabe que casi seguro rechazará.
DateTime oldestBirthDate(DateTime today) =>
    DateTime(today.year - AppConstants.maxPersonAgeYears.value, today.month, today.day);

/// La fecha con la que abre el selector cuando aún no hay una: la de hoy hace [AppConstants.birthDatePickerInitialAgeYears]
/// años, para no obligar a retroceder décadas desde hoy.
DateTime initialBirthDateForPicker(DateTime today) =>
    DateTime(today.year - AppConstants.birthDatePickerInitialAgeYears.value, today.month, today.day);

/// Revisa una fecha de nacimiento; null si sirve. [today] se pasa para que sea una función pura (y para las pruebas).
BirthDateIssue? checkBirthDate(DateTime? value, {required DateTime today}) {
  if (value == null) return BirthDateIssue.empty;
  final day = dateOnly(value);
  if (day.isAfter(dateOnly(today))) return BirthDateIssue.inTheFuture;
  if (day.isBefore(oldestBirthDate(dateOnly(today)))) return BirthDateIssue.tooOld;
  return null;
}

/// «yyyy-MM-dd», como la espera y la manda el backend (un `LocalDate`, sin hora ni zona).
String formatBirthDateForApi(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

/// La fecha que manda el backend («yyyy-MM-dd»); null si no hay o no se entiende. Se arma por partes: `DateTime.parse`
/// de un día solo lo lee a medianoche UTC y, en zonas detrás de UTC, mostraría el día anterior.
DateTime? parseBirthDate(Object? value) {
  if (value is! String) return null;
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(value);
  if (match == null) return null;
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final date = DateTime(year, month, day);
  // Un 31 de febrero se «corrige» solo a marzo: eso no es la fecha que dijo el backend.
  return date.month == month && date.day == day ? date : null;
}
