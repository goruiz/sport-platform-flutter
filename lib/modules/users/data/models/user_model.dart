import 'package:sport_platform/modules/users/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    super.firstName,
    super.middleName,
    super.lastName,
    super.secondLastName,
    super.username,
    super.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String? ?? '',
        firstName: json['firstName'] as String?,
        middleName: json['middleName'] as String?,
        lastName: json['lastName'] as String?,
        secondLastName: json['secondLastName'] as String?,
        username: json['username'] as String?,
        email: json['email'] as String?,
      );
}
