/// Un tramo de tiempo de una cancha, con su hora de inicio y de fin.
class CourtTimeSlot {
  final DateTime startsAt;
  final DateTime endsAt;

  const CourtTimeSlot({required this.startsAt, required this.endsAt});

  Duration get duration => endsAt.difference(startsAt);

  factory CourtTimeSlot.fromJson(Map<String, dynamic> json) => CourtTimeSlot(
        startsAt: DateTime.parse(json['startsAt'].toString()),
        endsAt: DateTime.parse(json['endsAt'].toString()),
      );
}

/// Un tramo que ocupa un partido. Los nombres de los equipos son null si el jugador no ve alguno de ellos.
class CourtBusySlot extends CourtTimeSlot {
  final String matchId;
  final String? homeTeamName;
  final String? awayTeamName;

  const CourtBusySlot({
    required super.startsAt,
    required super.endsAt,
    required this.matchId,
    this.homeTeamName,
    this.awayTeamName,
  });

  factory CourtBusySlot.fromJson(Map<String, dynamic> json) => CourtBusySlot(
        startsAt: DateTime.parse(json['startsAt'].toString()),
        endsAt: DateTime.parse(json['endsAt'].toString()),
        matchId: json['matchId']?.toString() ?? '',
        homeTeamName: json['homeTeamName']?.toString(),
        awayTeamName: json['awayTeamName']?.toString(),
      );
}

/// Cómo está un día de una cancha: de qué hora a qué hora abre, qué tramos ocupan los partidos y cuáles quedan libres.
/// Lo calcula el backend (`GET /courts/{id}/availability`): la apertura es la misma para todas las canchas y lo ocupado
/// sale de los partidos programados, porque no hay horarios cargados por cancha.
class CourtAvailabilityModel {
  final String courtId;
  final DateTime date;

  /// Hora de apertura y de cierre, «HH:mm».
  final String opensAt;
  final String closesAt;
  final List<CourtBusySlot> busySlots;
  final List<CourtTimeSlot> freeSlots;

  const CourtAvailabilityModel({
    required this.courtId,
    required this.date,
    required this.opensAt,
    required this.closesAt,
    this.busySlots = const [],
    this.freeSlots = const [],
  });

  factory CourtAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return CourtAvailabilityModel(
      courtId: json['courtId']?.toString() ?? '',
      date: DateTime.parse(json['date'].toString()),
      opensAt: _hourAndMinute(json['opensAt']),
      closesAt: _hourAndMinute(json['closesAt']),
      busySlots: _readList(json['busySlots'], CourtBusySlot.fromJson),
      freeSlots: _readList(json['freeSlots'], CourtTimeSlot.fromJson),
    );
  }

  static List<T> _readList<T>(dynamic raw, T Function(Map<String, dynamic>) read) =>
      raw is List ? [for (final item in raw) read(item as Map<String, dynamic>)] : <T>[];

  /// El backend manda la hora como «08:00:00»: se muestra «08:00».
  static String _hourAndMinute(dynamic raw) {
    final text = raw?.toString() ?? '';
    return text.length >= 5 ? text.substring(0, 5) : text;
  }
}
