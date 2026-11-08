import 'package:sport_platform/core/network/api_error_codes.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/enums/match_status.dart';
import 'package:sport_platform/modules/matches/data/models/match_attendance_model.dart';

/// Por qué el backend rechaza una respuesta de asistencia (`MatchAttendanceError`), con la frase que se le muestra.
enum MatchAttendanceError {
  notAParticipant('NOT_A_PARTICIPANT', 'match_detail.attendance.error_not_participant'),
  matchNotOpen('MATCH_NOT_OPEN', 'match_detail.attendance.error_closed');

  const MatchAttendanceError(this.backendCode, this.translationKey);

  final String backendCode;
  final String translationKey;

  /// El rechazo que dijo el backend; null si fue por otra cosa.
  static MatchAttendanceError? fromBackend(ApiErrorCodes codes) =>
      codes.firstOf(values, (error) => error.backendCode);
}

/// El jugador del equipo [myTeamId] juega este partido (de local o de visitante).
bool playsInMatch(MatchModel match, String? myTeamId) {
  if (myTeamId == null || myTeamId.isEmpty) return false;
  return match.homeTeamId == myTeamId || match.awayTeamId == myTeamId;
}

/// Todavía se puede responder si va a asistir: el partido aún no empieza y no está aplazado, suspendido ni cancelado
/// (de un partido aplazado no se sabe cuándo se juega). El backend decide al recibir la respuesta; esto solo evita
/// ofrecer botones que se van a rechazar.
bool canAnswerAttendance(MatchModel match, DateTime now) {
  final isOpenStatus = match.status == MatchStatus.scheduled || match.status == MatchStatus.rescheduled;
  return isOpenStatus && !match.hasScore && match.matchDate.isAfter(now);
}

/// Quiénes de un equipo van y quiénes no, por nombre.
class TeamAttendance {
  final List<MatchAttendee> confirmed;
  final List<MatchAttendee> declined;

  const TeamAttendance({this.confirmed = const [], this.declined = const []});

  bool get hasAnswers => confirmed.isNotEmpty || declined.isNotEmpty;
}

/// De lo que respondieron los jugadores del partido, lo del equipo [teamId] (el del propio jugador): el rival no se
/// muestra. Cada grupo sale por nombre, sin distinguir mayúsculas; uno sin nombre va al final.
TeamAttendance splitTeamAttendance(Iterable<MatchAttendee> attendees, String? teamId) {
  if (teamId == null || teamId.isEmpty) return const TeamAttendance();
  final ofTeam = attendees.where((attendee) => attendee.teamId == teamId).toList();
  List<MatchAttendee> withStatus(AttendanceStatus status) =>
      ofTeam.where((attendee) => attendee.status == status).toList()..sort(_compareByName);
  return TeamAttendance(
    confirmed: withStatus(AttendanceStatus.confirmed),
    declined: withStatus(AttendanceStatus.declined),
  );
}

int _compareByName(MatchAttendee a, MatchAttendee b) {
  final nameA = a.playerName;
  final nameB = b.playerName;
  if (nameA == null || nameB == null) {
    if (nameA == nameB) return 0;
    return nameA == null ? 1 : -1;
  }
  return nameA.toLowerCase().compareTo(nameB.toLowerCase());
}
