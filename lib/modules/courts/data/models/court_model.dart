import 'package:sport_platform/core/network/json_reader.dart';

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
    final reader = JsonReader(json, resource: 'cancha');
    return CourtModel(
      id: reader.requiredString('id'),
      name: reader.requiredString('name'),
      description: reader.optionalString('description'),
      location: reader.optionalString('location'),
      sportComplexId: reader.optionalString('sportComplexId'),
      sportComplexName: reader.optionalString('sportComplexName'),
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
