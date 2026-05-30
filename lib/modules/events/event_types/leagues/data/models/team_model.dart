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
    return TeamModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      logoUrl: json['logoUrl']?.toString(),
      categoryId: json['categoryId']?.toString(),
      status: json['status']?.toString(),
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
