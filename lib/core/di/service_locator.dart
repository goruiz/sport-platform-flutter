import 'package:get_it/get_it.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/courts_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/league_matches_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/league_schedule_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/league_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/league_teams_event_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/standings_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/teams_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/repositories/i_league_matches_repository.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/repositories/i_league_schedule_repository.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/repositories/i_league_teams_repository.dart';
import 'package:sport_platform/modules/events/shared/data/providers/events_notifier.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerLazySingleton<ILeagueTeamsRepository>(() => LeagueTeamsEventService());
  getIt.registerLazySingleton<ILeagueMatchesRepository>(() => LeagueMatchesService());
  getIt.registerLazySingleton<ILeagueScheduleRepository>(() => LeagueScheduleService());

  getIt.registerLazySingleton<StandingsService>(() => StandingsService());
  getIt.registerLazySingleton<TeamsService>(() => TeamsService());
  getIt.registerLazySingleton<PlayersService>(() => PlayersService());
  getIt.registerLazySingleton<CourtsService>(() => CourtsService());
  getIt.registerLazySingleton<EventsNotifier>(
    () => EventsNotifier(LeagueService()),
    instanceName: 'leagues',
  );
}
