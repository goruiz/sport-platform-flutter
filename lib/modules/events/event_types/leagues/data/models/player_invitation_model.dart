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

  factory PlayerInvitation.fromJson(Map<String, dynamic> json) =>
      PlayerInvitation(
        email: json['email']?.toString() ?? '',
        firstName: json['firstName']?.toString(),
        lastName: json['lastName']?.toString(),
        isExisting: json['isExisting'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'email': email,
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        'isExisting': isExisting,
      };

  PlayerInvitation copyWith({
    String? email,
    String? firstName,
    String? lastName,
    bool? isExisting,
  }) =>
      PlayerInvitation(
        email: email ?? this.email,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        isExisting: isExisting ?? this.isExisting,
      );
}
