import 'package:get_it/get_it.dart';
import 'package:sport_platform/modules/events/leagues/data/datasource/courts_service.dart';
import 'package:sport_platform/modules/events/leagues/data/datasource/league_detail_service.dart';
import 'package:sport_platform/modules/events/leagues/data/datasource/teams_service.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerLazySingleton<LeagueDetailService>(() => LeagueDetailService());
  getIt.registerLazySingleton<TeamsService>(() => TeamsService());
  getIt.registerLazySingleton<CourtsService>(() => CourtsService());
}
