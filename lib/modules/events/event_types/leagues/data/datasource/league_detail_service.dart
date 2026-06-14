import 'package:sport_platform/modules/events/event_types/leagues/domain/repositories/i_league_matches_repository.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/repositories/i_league_schedule_repository.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/repositories/i_league_teams_repository.dart';
import '../models/event_schedule_config_model.dart';
import '../models/match_model.dart';
import '../models/team_event_model.dart';

/// Facade that aggregates the three league repositories into a single entry
/// point for consumers that need cross-domain operations (e.g. AutoScheduleSheet).
class LeagueDetailService {
  final ILeagueTeamsRepository _teams;
  final ILeagueMatchesRepository _matches;
  final ILeagueScheduleRepository _schedule;

  LeagueDetailService({
    required ILeagueTeamsRepository teams,
    required ILeagueMatchesRepository matches,
    required ILeagueScheduleRepository schedule,
  })  : _teams = teams,
        _matches = matches,
        _schedule = schedule;

  // --- Teams ---

  Future<List<TeamEventModel>> getTeamsByEvent(String eventId) =>
      _teams.getByEvent(eventId);

  Future<TeamEventModel> addTeam(String teamId, String eventId) =>
      _teams.add(teamId, eventId);

  Future<void> removeTeam(String teamsEventsId) =>
      _teams.remove(teamsEventsId);

  // --- Matches ---

  Future<List<MatchModel>> getMatchesByEvent(String eventId) =>
      _matches.getByEvent(eventId);

  Future<MatchModel> createMatch(Map<String, dynamic> data) =>
      _matches.create(data);

  Future<MatchModel> updateMatch(String id, Map<String, dynamic> data) =>
      _matches.update(id, data);

  Future<void> deleteMatch(String id) => _matches.delete(id);

  /// [toDate] null → aplaza (POSTPONED). Con fecha → reprograma a esa fecha.
  Future<List<MatchModel>> rescheduleDateMatches(
    String eventId,
    DateTime fromDate, {
    DateTime? toDate,
  }) =>
      _matches.rescheduleDate(eventId, fromDate, toDate: toDate);

  // --- Schedule ---

  Future<EventScheduleConfigModel?> getScheduleConfig(String eventId) =>
      _schedule.getConfig(eventId);

  Future<EventScheduleConfigModel> saveScheduleConfig(
    String eventId,
    Map<String, dynamic> data,
  ) =>
      _schedule.saveConfig(eventId, data);

  Future<List<MatchModel>> generateSchedule(String eventId) =>
      _schedule.generate(eventId);
}
