import 'package:get_it/get_it.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/courts_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/league_detail_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/league_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/teams_service.dart';
import 'package:sport_platform/modules/events/shared/data/providers/events_notifier.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerLazySingleton<LeagueDetailService>(() => LeagueDetailService());
  getIt.registerLazySingleton<TeamsService>(() => TeamsService());
  getIt.registerLazySingleton<PlayersService>(() => PlayersService());
  getIt.registerLazySingleton<CourtsService>(() => CourtsService());
  getIt.registerLazySingleton<EventsNotifier>(
    () => EventsNotifier(LeagueService()),
    instanceName: 'leagues',
  );
}
