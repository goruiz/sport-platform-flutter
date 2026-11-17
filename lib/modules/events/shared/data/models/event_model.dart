import 'package:sport_platform/core/network/json_reader.dart';
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
    final reader = JsonReader(json, resource: 'evento');
    return EventModel(
      id: reader.requiredString('id'),
      name: reader.requiredString('name'),
      description: reader.optionalString('description'),
      format: reader.textOrEmpty('format'),
      // El estado es texto libre en el backend: uno vacío o desconocido se enseña tal cual (ver EventStatus).
      status: reader.textOrEmpty('status'),
      startDate: reader.requiredDateTime('startDate'),
      endDate: reader.requiredDateTime('endDate'),
      createdAt: reader.requiredDateTime('createdAt'),
      updatedAt: reader.optionalDateTime('updatedAt'),
      eventTypeName: eventType?['name']?.toString(),
      formatRules: EventFormatRules.fromJson(eventFormat),
      minPlayersPerTeam: reader.optionalInt('minPlayersPerTeam'),
      maxPlayersPerTeam: reader.optionalInt('maxPlayersPerTeam'),
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

  static String _apiDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
