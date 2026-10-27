import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/enums/match_status.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';

/// Un partido listo para usar en los tests: solo se dice lo que importa para la prueba.
MatchModel matchOf({
  String id = 'match-1',
  String homeTeamId = 'home',
  String awayTeamId = 'away',
  required DateTime date,
  MatchStatus status = MatchStatus.scheduled,
  int? homeScore,
  int? awayScore,
  String eventId = 'event-1',
}) {
  return MatchModel(
    id: id,
    homeTeamId: homeTeamId,
    awayTeamId: awayTeamId,
    matchDate: date,
    status: status,
    homeScore: homeScore,
    awayScore: awayScore,
    eventId: eventId,
    createdAt: DateTime(2026, 1, 1),
  );
}

EventModel eventOf({
  String id = 'event-1',
  String name = 'Liga',
  String status = 'ACTIVE',
  required DateTime startDate,
  required DateTime endDate,
}) {
  return EventModel(
    id: id,
    name: name,
    format: '',
    status: status,
    startDate: startDate,
    endDate: endDate,
    createdAt: DateTime(2026, 1, 1),
  );
}
