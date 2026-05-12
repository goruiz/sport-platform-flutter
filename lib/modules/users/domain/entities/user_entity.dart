class UserEntity {
  final String id;
  final String? idRole;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? secondLastName;
  final String? username;
  final String? email;
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
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
    this.deletedBy,
    this.deletedAt,
  });

  String get fullName {
    final parts = [firstName, middleName, lastName, secondLastName]
        .where((p) => p != null && p.isNotEmpty)
        .join(' ');
    return parts.isEmpty ? username ?? '' : parts;
  }

  bool get isDeleted => deletedAt != null;
}
