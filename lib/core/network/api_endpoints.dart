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

  // Events
  static const String events = '/events';
  static String eventById(String id) => '/events/$id';

  // Matches
  static const String matches = '/matches';
  static String matchById(String id) => '/matches/$id';

  // Menu
  static const String menu = '/menu';

  // Rankings
  static const String rankings = '/rankings';

  // Reports
  static const String reports = '/reports';

  // Leagues
  static const String leagues = '/ligas';
  static String leagueById(String id) => '/ligas/$id';
}
