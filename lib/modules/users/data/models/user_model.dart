import 'package:sport_platform/modules/users/domain/birth_date_rules.dart';
import 'package:sport_platform/modules/users/domain/entities/user_entity.dart';
import 'package:sport_platform/modules/users/domain/enums/gender.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    super.firstName,
    super.middleName,
    super.lastName,
    super.secondLastName,
    super.username,
    super.email,
    super.gender,
    super.birthDate,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String? ?? '',
        firstName: json['firstName'] as String?,
        middleName: json['middleName'] as String?,
        lastName: json['lastName'] as String?,
        secondLastName: json['secondLastName'] as String?,
        username: json['username'] as String?,
        email: json['email'] as String?,
        gender: Gender.fromApi(json['gender'] as String?),
        birthDate: parseBirthDate(json['birthDate']),
      );
}
