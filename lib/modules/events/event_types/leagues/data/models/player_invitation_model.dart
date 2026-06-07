class PlayerInvitation {
  final String email;
  final String? firstName;
  final String? lastName;
  final bool isExisting;

  const PlayerInvitation({
    required this.email,
    this.firstName,
    this.lastName,
    required this.isExisting,
  });

  String get displayName {
    if (firstName != null &&
        firstName!.isNotEmpty &&
        lastName != null &&
        lastName!.isNotEmpty) {
      return '$firstName $lastName';
    }
    return email;
  }
}
