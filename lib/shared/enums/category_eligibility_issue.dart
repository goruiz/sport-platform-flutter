import 'package:sport_platform/core/network/api_error_codes.dart';

/// Por qué una persona no cumple lo que pide la categoría de un equipo (género y edad). Cada uno es el código estable que
/// manda el backend (`CategoryEligibilityError`) y la app lo explica en el idioma del usuario.
///
/// Llega de dos maneras: como el `message` de un 400 cuando alguien intenta ENTRAR al equipo (aceptar una invitación,
/// unirse con un código o registrarse con el enlace) y como `categoryIneligibility` de un equipo del jugador cuando ya está
/// dentro pero deja de cumplir (la categoría cambió sus reglas, o su perfil está incompleto): en ese caso no puede jugar.
enum CategoryEligibilityIssue {
  /// La categoría es del otro género.
  genderNotAllowed('CATEGORY_GENDER_NOT_ALLOWED'),

  /// La categoría pide un género y la persona aún no dijo el suyo.
  genderRequired('CATEGORY_GENDER_REQUIRED'),

  /// La categoría pide una edad y la persona aún no dijo su fecha de nacimiento.
  birthDateRequired('CATEGORY_BIRTH_DATE_REQUIRED'),

  /// Es menor que la edad mínima de la categoría.
  tooYoung('CATEGORY_TOO_YOUNG'),

  /// Es mayor que la edad máxima de la categoría.
  tooOld('CATEGORY_TOO_OLD');

  const CategoryEligibilityIssue(this.code);

  final String code;

  static CategoryEligibilityIssue? fromCode(String? code) {
    for (final issue in values) {
      if (issue.code == code) return issue;
    }
    return null;
  }

  /// El motivo que dice la respuesta de un rechazo; null si es otro (sin conexión, un 500, otro código...).
  static CategoryEligibilityIssue? fromException(Object error) =>
      ApiErrorCodes.of(error).firstOf(values, (issue) => issue.code);

  /// El motivo cuyo texto de rechazo es [key]; null si la clave es de otro motivo. Lo usan las pantallas que reciben del
  /// notificador la clave del texto y no el motivo.
  static CategoryEligibilityIssue? fromRefusalKey(String? key) {
    for (final issue in values) {
      if (issue.refusalKey == key) return issue;
    }
    return null;
  }

  /// Faltan datos del perfil: se arregla completándolo, a diferencia de los demás, que son un «no» de la categoría.
  bool get needsProfileData => this == genderRequired || this == birthDateRequired;

  /// El texto cuando la persona intenta entrar al equipo y la categoría no la admite.
  String get refusalKey => 'category_eligibility.refused.$code';

  /// El texto cuando la persona ya está en el equipo pero no puede jugar en él.
  String get noticeKey => 'category_eligibility.notice.$code';
}
