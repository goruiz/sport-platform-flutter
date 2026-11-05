// Reglas de los nombres y apellidos de una persona. Funciones puras: las usan el formulario de perfil y el registro
// por invitación.
//
// Un nombre sirve si solo tiene LETRAS (con tildes, ñ, ü…), separadas por espacios, guiones o apóstrofos
// («María José», «Ana-María», «O'Brien», «De la Cruz»). Los números y los demás símbolos no valen.
// El guion y el apóstrofo se permiten porque forman parte de nombres reales y bloquearlos le impediría registrarse
// a quien los lleva.

/// Por qué un nombre no sirve.
enum PersonNameIssue {
  empty,
  invalidCharacters;

  /// La clave de traducción del motivo. Que esté vacío lo dice cada pantalla con su propio texto («Ingresa tu nombre»).
  String? get translationKey => switch (this) {
        PersonNameIssue.empty => null,
        PersonNameIssue.invalidCharacters => 'profile.name_invalid',
      };
}

/// Un carácter que se puede teclear en un nombre: letra, marca de acento, espacio, guion o apóstrofo.
final RegExp personNameTypableCharacter = RegExp(r"[\p{L}\p{M} '’-]", unicode: true);

/// Un nombre completo y bien formado: palabras de letras unidas por espacios, guiones o apóstrofos, sin símbolos sueltos
/// ni separadores al principio o al final.
final RegExp _wellFormedPersonName = RegExp(
  r"^[\p{L}\p{M}]+(?:(?: +|['’-])[\p{L}\p{M}]+)*$",
  unicode: true,
);

/// El nombre queda en su forma de guardar: sin espacios en los extremos y con un solo espacio entre palabras.
String normalizePersonName(String value) => value.trim().replaceAll(RegExp(r' {2,}'), ' ');

/// Revisa un nombre o apellido; null si sirve. Un campo opcional ([required] falso) vacío también sirve.
PersonNameIssue? checkPersonName(String? value, {required bool required}) {
  final name = normalizePersonName(value ?? '');
  if (name.isEmpty) return required ? PersonNameIssue.empty : null;
  return _wellFormedPersonName.hasMatch(name) ? null : PersonNameIssue.invalidCharacters;
}
