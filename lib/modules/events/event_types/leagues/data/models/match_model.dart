import 'package:sport_platform/modules/events/event_types/leagues/domain/enums/match_status.dart';

class MatchModel {
  final String id;
  final String homeTeamId;
  final String awayTeamId;
  final DateTime matchDate;
  final String? location;
  final MatchStatus status;
  final int? homeScore;
  final int? awayScore;
  final String? courtId;
  final String eventId;
  final DateTime createdAt;

  /// Cuándo termina el partido (hora + duración + descanso); a partir de ahí se puede registrar su
  /// resultado. Lo calcula el backend: es null si no lo envía.
  final DateTime? endsAt;

  /// Los nombres de lo que apuntan los ids, que el backend manda al leer partidos para no tener que bajar todos los
  /// equipos y eventos solo para rotularlos. Null si el jugador no ve ese equipo o evento.
  final String? homeTeamName;
  final String? awayTeamName;
  final String? eventName;

  const MatchModel({
    required this.id,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.matchDate,
    this.location,
    required this.status,
    this.homeScore,
    this.awayScore,
    this.courtId,
    required this.eventId,
    required this.createdAt,
    this.endsAt,
    this.homeTeamName,
    this.awayTeamName,
    this.eventName,
  });

  bool get hasScore => homeScore != null && awayScore != null;

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id']?.toString() ?? '',
      homeTeamId: json['homeTeamId']?.toString() ?? '',
      awayTeamId: json['awayTeamId']?.toString() ?? '',
      matchDate: json['matchDate'] != null
          ? DateTime.parse(json['matchDate'].toString())
          : DateTime.now(),
      location: json['location']?.toString(),
      status: MatchStatus.fromString(json['status']?.toString() ?? 'SCHEDULED'),
      homeScore: json['homeScore'] as int?,
      awayScore: json['awayScore'] as int?,
      courtId: json['courtId']?.toString(),
      eventId: json['eventId']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      endsAt: json['endsAt'] != null
          ? DateTime.parse(json['endsAt'].toString())
          : null,
      homeTeamName: json['homeTeamName']?.toString(),
      awayTeamName: json['awayTeamName']?.toString(),
      eventName: json['eventName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'homeTeamId': homeTeamId,
        'awayTeamId': awayTeamId,
        'matchDate': apiDateTime(matchDate),
        'status': status.toJson(),
        'eventId': eventId,
        if (location != null) 'location': location,
        if (courtId != null) 'courtId': courtId,
        if (homeScore != null) 'homeScore': homeScore,
        if (awayScore != null) 'awayScore': awayScore,
      };

  MatchModel copyWith({
    String? id,
    String? homeTeamId,
    String? awayTeamId,
    DateTime? matchDate,
    String? location,
    MatchStatus? status,
    int? homeScore,
    int? awayScore,
    String? courtId,
    String? eventId,
    DateTime? createdAt,
    DateTime? endsAt,
    String? homeTeamName,
    String? awayTeamName,
    String? eventName,
  }) =>
      MatchModel(
        id: id ?? this.id,
        homeTeamId: homeTeamId ?? this.homeTeamId,
        awayTeamId: awayTeamId ?? this.awayTeamId,
        matchDate: matchDate ?? this.matchDate,
        location: location ?? this.location,
        status: status ?? this.status,
        homeScore: homeScore ?? this.homeScore,
        awayScore: awayScore ?? this.awayScore,
        courtId: courtId ?? this.courtId,
        eventId: eventId ?? this.eventId,
        createdAt: createdAt ?? this.createdAt,
        endsAt: endsAt ?? this.endsAt,
        homeTeamName: homeTeamName ?? this.homeTeamName,
        awayTeamName: awayTeamName ?? this.awayTeamName,
        eventName: eventName ?? this.eventName,
      );

  static String apiDateTime(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}'
      'T${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:00';
}
