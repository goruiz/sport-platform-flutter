import 'package:sport_platform/core/network/json_reader.dart';

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
    final reader = JsonReader(json, resource: 'complejo');
    return SportComplexModel(
      id: reader.requiredString('id'),
      name: reader.requiredString('name'),
      description: reader.optionalString('description'),
      location: reader.optionalString('location'),
      latitude: reader.optionalDouble('latitude'),
      longitude: reader.optionalDouble('longitude'),
    );
  }
}
