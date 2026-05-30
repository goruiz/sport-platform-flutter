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

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null) 'description': description,
        if (location != null) 'location': location,
        if (sportComplexId != null) 'sportComplexId': sportComplexId,
      };

  CourtModel copyWith({
    String? id,
    String? name,
    String? description,
    String? location,
    String? sportComplexId,
    String? sportComplexName,
  }) =>
      CourtModel(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        location: location ?? this.location,
        sportComplexId: sportComplexId ?? this.sportComplexId,
        sportComplexName: sportComplexName ?? this.sportComplexName,
      );

  String get displayName {
    if (sportComplexName != null && sportComplexName!.isNotEmpty) {
      return '$name — $sportComplexName';
    }
    return name;
  }
}
