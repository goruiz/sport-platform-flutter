import '../config/app_config.dart';

class ApiEndpoints {
  static String get baseUrl => AppConfig.baseUrl;

  // Auth
  static const String login = '/users/auth/login';
  static const String register = '/users/auth/register';
  static const String logout = '/users/auth/logout';
  static const String refreshToken = '/users/auth/refresh';

  // Users
  static const String users = '/users';
  static String userById(String id) => '/users/$id';

  // Teams
  static const String teams = '/teams';
  static String teamById(String id) => '/teams/$id';

  // Players
  static const String players = '/players';
  static String playerById(String id) => '/players/$id';
  static const String playersSearch = '/players/search';
  static const String playersInvite = '/players/invite';
  static const String playersInviteRegister = '/players/invite-register';
  static const String playersAuthRegister = '/players/auth/register';
  static String playersByTeam(String teamId) => '/players/by-team/$teamId';
  static String playerRemoveFromTeam(String id) =>
      '/players/$id/remove-from-team';

  // Events
  static const String events = '/events';
  static String eventById(String id) => '/events/$id';
  static String eventsByType(String typeId) => '/events/by-event-type/$typeId';
  static String eventsByTypeAndUser(String typeId, String userId) =>
      '/events/by-event-type/$typeId/by-user/$userId';

  // Matches
  static const String matches = '/matches';
  static String matchById(String id) => '/matches/$id';
  static String matchesByEvent(String eventId) => '/matches/by-event/$eventId';

  // Teams-events
  static String teamsEventsByEvent(String eventId) =>
      '/teams-events/by-event/$eventId';
  static const String teamsEvents = '/teams-events';
  static String teamsEventsById(String id) => '/teams-events/$id';
  static String teamsEventsHardDelete(String id) => '/teams-events/$id/hard';

  // Courts
  static const String courts = '/courts';

  // Sport Complexes
  static const String sportComplexes = '/sport-complexes';

  // Menu
  static const String menu = '/menu';

  // Rankings
  static const String rankings = '/rankings';

  // Reports
  static const String reports = '/reports';

  // Schedule config
  static String scheduleConfig(String eventId) =>
      '/events/$eventId/schedule-config';
  static String generateSchedule(String eventId) =>
      '/events/$eventId/schedule-config/generate';

  // Match day batch operations
  static String rescheduleDateMatches(String eventId) =>
      '/matches/by-event/$eventId/reschedule-date';

  // Match status transitions
  static String matchPostpone(String id) => '/matches/$id/postpone';
  static String matchSuspend(String id) => '/matches/$id/suspend';
  static String matchReschedule(String id) => '/matches/$id/reschedule';

  // Leagues
  static const String leagues = '/ligas';
  static String leagueById(String id) => '/ligas/$id';

  // Standings
  static const String standings = '/events';
  static String standingsByEvent(String eventId) =>
      '/events/$eventId/standings';

}
