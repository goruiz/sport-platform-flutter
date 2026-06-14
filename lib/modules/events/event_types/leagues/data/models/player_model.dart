class PlayerModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? profilePhotoUrl;
  final String? status;
  final String? teamId;
  final String? teamName;

  const PlayerModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.profilePhotoUrl,
    this.status,
    this.teamId,
    this.teamName,
  });

  String get fullName => '$firstName $lastName';

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      profilePhotoUrl: json['profilePhotoUrl']?.toString(),
      status: json['status']?.toString(),
      teamId: json['teamId']?.toString(),
      teamName: json['teamName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        if (phone != null) 'phone': phone,
        if (profilePhotoUrl != null) 'profilePhotoUrl': profilePhotoUrl,
        if (status != null) 'status': status,
        if (teamId != null) 'teamId': teamId,
        if (teamName != null) 'teamName': teamName,
      };

  PlayerModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? profilePhotoUrl,
    String? status,
    String? teamId,
    String? teamName,
  }) =>
      PlayerModel(
        id: id ?? this.id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
        status: status ?? this.status,
        teamId: teamId ?? this.teamId,
        teamName: teamName ?? this.teamName,
      );
}
