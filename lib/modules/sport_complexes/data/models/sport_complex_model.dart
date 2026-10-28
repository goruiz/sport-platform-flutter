/// Un complejo deportivo: dónde queda y, si el organizador la marcó, su ubicación exacta en el mapa.
class SportComplexModel {
  final String id;
  final String name;
  final String? description;

  /// La dirección o referencia en texto.
  final String? location;
  final double? latitude;
  final double? longitude;

  const SportComplexModel({
    required this.id,
    required this.name,
    this.description,
    this.location,
    this.latitude,
    this.longitude,
  });

  /// El backend guarda las dos coordenadas o ninguna; los complejos anteriores a la ubicación no tienen.
  bool get hasMapPosition => latitude != null && longitude != null;

  factory SportComplexModel.fromJson(Map<String, dynamic> json) {
    return SportComplexModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      location: json['location']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
