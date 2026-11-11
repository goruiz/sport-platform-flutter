import 'package:dio/dio.dart';

/// Por qué el backend rechazó el género o la fecha de nacimiento del perfil. Cada uno es el código estable que manda en
/// `data: {campo: CÓDIGO}` y la app lo explica en el idioma del usuario (`profile.errors.<código>`).
enum ProfileDataError {
  /// El género no es uno de los que se ofrecen.
  invalidGender('INVALID_GENDER'),

  /// La fecha es futura o de alguien de más años de los que puede tener una persona.
  invalidBirthDate('INVALID_BIRTH_DATE');

  const ProfileDataError(this.code);

  final String code;

  static ProfileDataError? fromCode(Object? code) {
    for (final error in values) {
      if (error.code == code) return error;
    }
    return null;
  }

  String get translationKey => 'profile.errors.$code';
}

/// Lo que el backend dijo de cada campo del perfil que tiene motivo propio, para ponerlo bajo su control.
class ProfileFieldErrors {
  final ProfileDataError? gender;
  final ProfileDataError? birthDate;

  const ProfileFieldErrors({this.gender, this.birthDate});

  static const none = ProfileFieldErrors();

  bool get isEmpty => gender == null && birthDate == null;

  /// Lee los motivos por campo de un 400 de validación; sin ninguno conocido (sin conexión, un 500...) queda vacío y la
  /// pantalla dice el error general.
  factory ProfileFieldErrors.fromException(Object error) {
    if (error is! DioException) return none;
    final body = error.response?.data;
    final data = body is Map<String, dynamic> ? body['data'] : null;
    if (data is! Map) return none;
    return ProfileFieldErrors(
      gender: ProfileDataError.fromCode(data['gender']),
      birthDate: ProfileDataError.fromCode(data['birthDate']),
    );
  }
}
