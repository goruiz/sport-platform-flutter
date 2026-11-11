import 'package:sport_platform/modules/users/domain/enums/gender.dart';

class UserEntity {
  final String id;
  final String? idRole;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? secondLastName;
  final String? username;
  final String? email;

  /// Lo que una categoría de equipo puede exigir. Null mientras la persona no los diga (cuentas anteriores a pedirlos).
  final Gender? gender;
  final DateTime? birthDate;
  final String? createdBy;
  final DateTime? createdAt;
  final String? updatedBy;
  final DateTime? updatedAt;
  final String? deletedBy;
  final DateTime? deletedAt;

  const UserEntity({
    required this.id,
    this.idRole,
    this.firstName,
    this.middleName,
    this.lastName,
    this.secondLastName,
    this.username,
    this.email,
    this.gender,
    this.birthDate,
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
    this.deletedBy,
    this.deletedAt,
  });

  /// La misma cuenta con el género y la fecha de nacimiento dados; los que son null conservan lo que ya tenía.
  UserEntity withPersonalData({Gender? gender, DateTime? birthDate}) => UserEntity(
        id: id,
        idRole: idRole,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        secondLastName: secondLastName,
        username: username,
        email: email,
        gender: gender ?? this.gender,
        birthDate: birthDate ?? this.birthDate,
        createdBy: createdBy,
        createdAt: createdAt,
        updatedBy: updatedBy,
        updatedAt: updatedAt,
        deletedBy: deletedBy,
        deletedAt: deletedAt,
      );

  String get fullName {
    final parts = [firstName, middleName, lastName, secondLastName]
        .where((p) => p != null && p.isNotEmpty)
        .join(' ');
    return parts.isEmpty ? username ?? '' : parts;
  }

  bool get isDeleted => deletedAt != null;
}
