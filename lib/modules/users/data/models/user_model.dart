import 'package:sport_platform/core/network/json_reader.dart';
import 'package:sport_platform/core/utils/birth_date_rules.dart';
import 'package:sport_platform/core/models/user_entity.dart';
import 'package:sport_platform/core/models/gender.dart';

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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, resource: 'cuenta');
    return UserModel(
      id: reader.requiredString('id'),
      firstName: reader.optionalString('firstName'),
      middleName: reader.optionalString('middleName'),
      lastName: reader.optionalString('lastName'),
      secondLastName: reader.optionalString('secondLastName'),
      username: reader.optionalString('username'),
      email: reader.optionalString('email'),
      gender: Gender.fromApi(reader.optionalString('gender')),
      birthDate: parseBirthDate(json['birthDate']),
    );
  }
}
