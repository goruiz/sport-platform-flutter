import 'package:sport_platform/core/modules/module_registry.dart';
import 'package:sport_platform/modules/events/presentation/pages/events_page.dart';
import 'package:sport_platform/modules/events/leagues/presentation/pages/leagues_page.dart';
import 'package:sport_platform/modules/matches/presentation/pages/matches_page.dart';
import 'package:sport_platform/modules/rankings/presentation/pages/rankings_page.dart';
import 'package:sport_platform/modules/reports/presentation/pages/reports_page.dart';
import 'package:sport_platform/modules/teams/presentation/pages/teams_page.dart';
import 'package:sport_platform/modules/users/presentation/pages/profile_page.dart';

/// Registers every application module in one place.
/// To add a new module: import its page and add one ModuleRegistry.register() line.
/// The URL must match the value stored in the menu.url column in the database.
void registerModules() {
  ModuleRegistry.register('/teams',    (item) => TeamsPage(item: item));
  ModuleRegistry.register('/events',   (item) => EventsPage(item: item));
  ModuleRegistry.register('/rankings', (item) => RankingsPage(item: item));
  ModuleRegistry.register('/matches',  (item) => MatchesPage(item: item));
  ModuleRegistry.register('/reports',  (item) => ReportsPage(item: item));
  ModuleRegistry.register('/profile',  (item) => ProfilePage(item: item));
  ModuleRegistry.register('/leagues',    (item) => LeaguesPage(item: item));
}
