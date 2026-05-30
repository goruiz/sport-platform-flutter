class CourtModel {
  final String id;
  final String name;
  final String? description;
  final String? location;
  final String? sportComplexId;
  final String? sportComplexName;

  const CourtModel({
    required this.id,
    required this.name,
    this.description,
    this.location,
    this.sportComplexId,
    this.sportComplexName,
  });

  factory CourtModel.fromJson(Map<String, dynamic> json) {
    return CourtModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      location: json['location']?.toString(),
      sportComplexId: json['sportComplexId']?.toString(),
      sportComplexName: json['sportComplexName']?.toString(),
    );
  }

  String get displayName {
    if (sportComplexName != null && sportComplexName!.isNotEmpty) {
      return '$name — $sportComplexName';
    }
    return name;
  }
}
