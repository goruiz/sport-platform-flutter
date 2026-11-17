import 'package:sport_platform/core/network/json_reader.dart';
import 'package:sport_platform/shared/enums/match_status.dart';

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

  /// El evento al que pertenece; null en un partido que se creó sin evento.
  final String? eventId;
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
    this.eventId,
    required this.createdAt,
    this.endsAt,
    this.homeTeamName,
    this.awayTeamName,
    this.eventName,
  });

  bool get hasScore => homeScore != null && awayScore != null;

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, resource: 'partido');
    return MatchModel(
      id: reader.requiredString('id'),
      homeTeamId: reader.requiredString('homeTeamId'),
      awayTeamId: reader.requiredString('awayTeamId'),
      matchDate: reader.requiredDateTime('matchDate'),
      location: reader.optionalString('location'),
      status: MatchStatus.fromApi(reader.optionalString('status')),
      homeScore: reader.optionalInt('homeScore'),
      awayScore: reader.optionalInt('awayScore'),
      courtId: reader.optionalString('courtId'),
      eventId: reader.optionalString('eventId'),
      createdAt: reader.requiredDateTime('createdAt'),
      endsAt: reader.optionalDateTime('endsAt'),
      homeTeamName: reader.optionalString('homeTeamName'),
      awayTeamName: reader.optionalString('awayTeamName'),
      eventName: reader.optionalString('eventName'),
    );
  }

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
}
