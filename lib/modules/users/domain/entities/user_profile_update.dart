/// Datos que el usuario completa en su perfil. Los opcionales sin valor son `null`.
class UserProfileUpdate {
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? secondLastName;
  final String username;

  const UserProfileUpdate({
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.secondLastName,
    required this.username,
  });
}
