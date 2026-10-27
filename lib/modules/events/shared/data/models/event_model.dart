import 'package:sport_platform/modules/events/shared/domain/enums/event_format_structure.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/event_status.dart';

class EventModel {
  final String id;
  final String name;
  final String? description;
  final String format;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? eventTypeName;

  /// La estructura de juego de su formato; null si el evento no tiene formato o su formato no
  /// tiene reglas (entonces es una liga como siempre y no hay campeonato que mostrar).
  final EventFormatStructure? formatStructure;

  const EventModel({
    required this.id,
    required this.name,
    this.description,
    required this.format,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    this.updatedAt,
    this.eventTypeName,
    this.formatStructure,
  });

  /// Su estado como enum; null si el backend trae un texto distinto de los cuatro conocidos.
  EventStatus? get statusType => EventStatus.fromApi(status);

  /// El evento tiene un campeonato que seguir (fases, tablas o llave) según su formato.
  bool get hasChampionship => formatStructure != null;

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final eventType = json['eventType'] as Map<String, dynamic>?;
    final eventFormat = json['eventFormat'] as Map<String, dynamic>?;
    return EventModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      format: json['format']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'].toString())
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'].toString())
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : null,
      eventTypeName: eventType?['name']?.toString(),
      formatStructure:
          EventFormatStructure.fromApi(eventFormat?['structure']?.toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'format': format,
        'status': status,
        'startDate': _apiDate(startDate),
        'endDate': _apiDate(endDate),
      };

  EventModel copyWith({
    String? id,
    String? name,
    String? description,
    String? format,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? eventTypeName,
    EventFormatStructure? formatStructure,
  }) =>
      EventModel(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        format: format ?? this.format,
        status: status ?? this.status,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        eventTypeName: eventTypeName ?? this.eventTypeName,
        formatStructure: formatStructure ?? this.formatStructure,
      );

  static String _apiDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
