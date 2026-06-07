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
}
