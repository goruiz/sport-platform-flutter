import 'package:sport_platform/modules/events/shared/data/models/event_format_rules.dart';
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

  /// Las reglas de su formato (estructura, puntos, desempates…); null si el evento no tiene formato o su formato no
  /// tiene reglas (entonces es una liga como siempre y no hay campeonato que mostrar).
  final EventFormatRules? formatRules;

  /// Los límites de jugadores por equipo que fijó el organizador; null si no puso alguno.
  final int? minPlayersPerTeam;
  final int? maxPlayersPerTeam;

  /// Los ids de los complejos deportivos donde se juega el evento (los que el organizador le asignó); vacío si no
  /// eligió ninguno.
  final List<String> sportComplexIds;

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
    this.formatRules,
    this.minPlayersPerTeam,
    this.maxPlayersPerTeam,
    this.sportComplexIds = const [],
  });

  /// La estructura de juego de su formato; null si no tiene reglas.
  EventFormatStructure? get formatStructure => formatRules?.structure;

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
      formatRules: EventFormatRules.fromJson(eventFormat),
      minPlayersPerTeam: _asInt(json['minPlayersPerTeam']),
      maxPlayersPerTeam: _asInt(json['maxPlayersPerTeam']),
      sportComplexIds: [
        for (final id in json['sportComplexIds'] as List<dynamic>? ?? const []) id.toString(),
      ],
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
    EventFormatRules? formatRules,
    int? minPlayersPerTeam,
    int? maxPlayersPerTeam,
    List<String>? sportComplexIds,
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
        formatRules: formatRules ?? this.formatRules,
        minPlayersPerTeam: minPlayersPerTeam ?? this.minPlayersPerTeam,
        maxPlayersPerTeam: maxPlayersPerTeam ?? this.maxPlayersPerTeam,
        sportComplexIds: sportComplexIds ?? this.sportComplexIds,
      );

  static int? _asInt(dynamic value) => value is num ? value.toInt() : null;

  static String _apiDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
