import '../config/app_config.dart';

class ApiEndpoints {
  static String get baseUrl => AppConfig.baseUrl;

  // Auth
  static const String login = '/users/auth/login';
  static const String register = '/users/auth/register';
  static const String forgotPassword = '/users/auth/forgot-password';
  static const String resetPassword = '/users/auth/reset-password';
  static const String logout = '/users/auth/logout';
  static const String refreshToken = '/users/auth/refresh';
  static const String updateProfile = '/users/auth/update-profile';
  static const String changePassword = '/users/auth/change-password';
  static const String deleteAccount = '/users/auth/delete-account';
  static const String currentAccount = '/users/auth/me';
  static const String verifyEmail = '/users/auth/verify-email';
  static const String resendEmailVerification = '/users/auth/resend-verification';

  // Users
  static const String users = '/users';
  static String userById(String id) => '/users/$id';

  // Teams
  static String teamById(String id) => '/teams/$id';

  // Players
  static const String playersMe = '/players/me';
  static const String playersMePhoto = '/players/me/photo';
  static const String playersMeStats = '/players/me/stats';
  static const String playersAuthRegister = '/players/auth/register';
  static const String playersJoinByCode = '/players/join-by-code';
  static String playersByTeam(String teamId) => '/players/by-team/$teamId';
  // Un jugador puede jugar en varios equipos (uno por organización): [teamId] dice de cuál sale.
  static String playerRemoveFromTeam(String id, {String? teamId}) =>
      '/players/$id/remove-from-team${teamId == null ? '' : '?teamId=$teamId'}';

  // Events
  static const String events = '/events';
  static const String eventsSearch = '/events/search';
  static String eventById(String id) => '/events/$id';
  static String eventsByType(String typeId) => '/events/by-event-type/$typeId';
  static String eventsByTypeAndUser(String typeId, String userId) =>
      '/events/by-event-type/$typeId/by-user/$userId';

  // Matches
  static String matchesByEvent(String eventId) => '/matches/by-event/$eventId';
  static const String matchesMine = '/matches/mine';
  static String matchesByCourt(String courtId) => '/matches/by-court/$courtId';
  static String matchAttendance(String matchId) => '/matches/$matchId/attendance';
  // Avisos de un problema con el resultado (disputas): los abre y ve el dirigente de equipo, los responde el organizador
  static String matchDisputes(String matchId) => '/matches/$matchId/disputes';

  // Match events (goals, assists, cards and fouls of a match): the app only reads them
  static String matchEventsByMatch(String matchId) =>
      '/match-events/by-match/$matchId';

  // Team invitations (answered by the invited person)
  static const String teamInvitationsMine = '/team-invitations/mine';
  static String teamInvitationAccept(String id) =>
      '/team-invitations/$id/accept';
  static String teamInvitationDecline(String id) =>
      '/team-invitations/$id/decline';

  // Teams-events
  static String teamsEventsByEvent(String eventId) =>
      '/teams-events/by-event/$eventId';
  static String teamsEventsById(String id) => '/teams-events/$id';

  // Courts
  static const String courts = '/courts';
  static String courtAvailability(String courtId) =>
      '/courts/$courtId/availability';

  // Sport Complexes
  static const String sportComplexes = '/sport-complexes';

  // Menu
  static const String menuForCurrentUser = '/menu/for-current-user';

  // Rankings
  static const String rankings = '/rankings';

  // Reports
  static const String reports = '/reports';

  // Leagues
  static const String leagues = '/ligas';
  static String leagueById(String id) => '/ligas/$id';

  // Standings
  static const String standings = '/events';
  static String standingsByEvent(String eventId) =>
      '/events/$eventId/standings';

  // Championship (phases, tables and knockout bracket according to the event's format)
  static String championshipByEvent(String eventId) =>
      '/events/$eventId/championship';

  // Scorers, assists and cards of an event
  static String playerStatsByEvent(String eventId) =>
      '/events/$eventId/player-stats';
}
