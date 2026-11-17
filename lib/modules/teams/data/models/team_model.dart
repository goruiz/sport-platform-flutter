import 'package:sport_platform/core/network/json_reader.dart';

class TeamModel {
  final String id;
  final String name;
  final String? logoUrl;
  final String? categoryId;
  final String? status;

  const TeamModel({
    required this.id,
    required this.name,
    this.logoUrl,
    this.categoryId,
    this.status,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, resource: 'equipo');
    return TeamModel(
      id: reader.requiredString('id'),
      name: reader.requiredString('name'),
      logoUrl: reader.optionalString('logoUrl'),
      categoryId: reader.optionalString('categoryId'),
      status: reader.optionalString('status'),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (logoUrl != null) 'logoUrl': logoUrl,
        if (categoryId != null) 'categoryId': categoryId,
        if (status != null) 'status': status,
      };

  TeamModel copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? categoryId,
    String? status,
  }) =>
      TeamModel(
        id: id ?? this.id,
        name: name ?? this.name,
        logoUrl: logoUrl ?? this.logoUrl,
        categoryId: categoryId ?? this.categoryId,
        status: status ?? this.status,
      );
}
