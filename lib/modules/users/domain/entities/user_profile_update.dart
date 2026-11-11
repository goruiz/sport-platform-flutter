import 'package:sport_platform/modules/users/domain/enums/gender.dart';

/// Datos que el usuario completa en su perfil. Los opcionales sin valor son `null`.
class UserProfileUpdate {
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? secondLastName;
  final String username;

  /// El género y la fecha de nacimiento que las categorías de los equipos pueden pedir. El backend ignora los que no se
  /// envían (no se pueden borrar una vez dichos).
  final Gender? gender;
  final DateTime? birthDate;

  const UserProfileUpdate({
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.secondLastName,
    required this.username,
    this.gender,
    this.birthDate,
  });
}
