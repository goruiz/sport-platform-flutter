import 'package:get_it/get_it.dart';
import 'package:sport_platform/core/routes/app_navigator.dart';
import 'package:sport_platform/core/services/session_expired_listener.dart';
import 'package:sport_platform/core/services/session_service.dart';
import 'package:sport_platform/modules/auth/presentation/pages/login_page.dart';
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
import 'package:sport_platform/modules/users/data/datasource/user_profile_service.dart';
import 'package:sport_platform/modules/users/domain/repositories/i_user_profile_repository.dart';
import 'package:sport_platform/shared/services/session_expired_handler.dart';

final getIt = GetIt.instance;

const _leaguesNotifierName = 'leagues';

void setupServiceLocator() {
  getIt.registerLazySingleton<SessionService>(
    () => SessionService(resetSessionScopedState: _resetSessionScopedServices),
  );
  getIt.registerLazySingleton<SessionExpiredListener>(
    () => SessionExpiredHandler(
      sessionService: getIt<SessionService>(),
      navigatorKey: AppNavigator.key,
      loginPageBuilder: () => const LoginPage(),
    ),
  );

  getIt.registerLazySingleton<IUserProfileRepository>(() => UserProfileService());

  getIt.registerLazySingleton<ILeagueTeamsRepository>(() => LeagueTeamsEventService());
  getIt.registerLazySingleton<ILeagueMatchesRepository>(() => LeagueMatchesService());
  getIt.registerLazySingleton<ILeagueScheduleRepository>(() => LeagueScheduleService());

  getIt.registerLazySingleton<StandingsService>(() => StandingsService());
  getIt.registerLazySingleton<TeamsService>(() => TeamsService());
  getIt.registerLazySingleton<PlayersService>(() => PlayersService());
  getIt.registerLazySingleton<CourtsService>(() => CourtsService());
  getIt.registerLazySingleton<EventsNotifier>(
    () => EventsNotifier(LeagueService()),
    instanceName: _leaguesNotifierName,
  );
}

/// Estado en memoria que pertenece al usuario de la sesión: no debe sobrevivir a ella
/// para que el siguiente usuario no vea datos del anterior.
void _resetSessionScopedServices() {
  if (getIt.isRegistered<EventsNotifier>(instanceName: _leaguesNotifierName)) {
    getIt.resetLazySingleton<EventsNotifier>(instanceName: _leaguesNotifierName);
  }
}
