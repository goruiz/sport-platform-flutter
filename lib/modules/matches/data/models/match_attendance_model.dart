/// La respuesta de un jugador a «¿vas a ir al partido?». El backend la guarda por nombre.
enum AttendanceStatus {
  confirmed('CONFIRMED'),
  declined('DECLINED');

  const AttendanceStatus(this.apiValue);

  final String apiValue;

  /// El estado que manda el backend; null si no hay respuesta o es un valor que la app no conoce.
  static AttendanceStatus? fromApi(Object? value) {
    for (final status in values) {
      if (status.apiValue == value) return status;
    }
    return null;
  }
}

/// Un jugador que respondió.
class MatchAttendee {
  final String playerId;

  /// Null si el jugador se borró después de responder.
  final String? playerName;
  final String teamId;
  final AttendanceStatus status;

  const MatchAttendee({
    required this.playerId,
    this.playerName,
    required this.teamId,
    required this.status,
  });

  /// Null si la respuesta trae un estado desconocido: no hay forma de mostrarla.
  static MatchAttendee? fromJson(Map<String, dynamic> json) {
    final status = AttendanceStatus.fromApi(json['status']);
    if (status == null) return null;
    return MatchAttendee(
      playerId: json['playerId']?.toString() ?? '',
      playerName: json['playerName']?.toString(),
      teamId: json['teamId']?.toString() ?? '',
      status: status,
    );
  }
}

/// Quiénes van a un partido: cuántos confirmaron y cuántos no, lo que respondió el propio jugador y, para los de los
/// equipos del partido, quién respondió qué (los demás reciben solo los totales).
class MatchAttendanceModel {
  final String matchId;
  final int confirmedCount;
  final int declinedCount;

  /// Lo que respondió el jugador de la cuenta; null si aún no respondió.
  final AttendanceStatus? myStatus;
  final List<MatchAttendee> attendees;

  const MatchAttendanceModel({
    required this.matchId,
    this.confirmedCount = 0,
    this.declinedCount = 0,
    this.myStatus,
    this.attendees = const [],
  });

  int get answeredCount => confirmedCount + declinedCount;

  factory MatchAttendanceModel.fromJson(Map<String, dynamic> json) {
    final rawAttendees = json['attendees'];
    return MatchAttendanceModel(
      matchId: json['matchId']?.toString() ?? '',
      confirmedCount: _asInt(json['confirmedCount']),
      declinedCount: _asInt(json['declinedCount']),
      myStatus: AttendanceStatus.fromApi(json['myStatus']),
      attendees: rawAttendees is List
          ? [
              for (final item in rawAttendees)
                ?MatchAttendee.fromJson(item as Map<String, dynamic>),
            ]
          : const [],
    );
  }

  static int _asInt(dynamic value) => value is num ? value.toInt() : 0;
}
