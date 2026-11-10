import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/services/session_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/teams_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/team_model.dart';
import 'package:sport_platform/modules/events/shared/data/datasource/events_search_service.dart';
import 'package:sport_platform/modules/events/shared/data/datasource/team_events_service.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/event_status.dart';
import 'package:sport_platform/modules/home/presentation/enums/menu_style.dart';
import 'package:sport_platform/modules/home/presentation/widgets/home_tab.dart';
import 'package:sport_platform/modules/matches/data/datasource/matches_service.dart';
import 'package:sport_platform/modules/players/data/datasource/team_invitations_service.dart';
import 'package:sport_platform/modules/players/presentation/providers/invitations_notifier.dart';
import 'package:sport_platform/modules/teams/presentation/providers/active_team_notifier.dart';
import 'package:sport_platform/modules/teams/presentation/widgets/active_team_pill.dart';
import 'package:sport_platform/modules/users/data/datasource/account_service.dart';
import 'package:sport_platform/modules/users/presentation/providers/email_verification_notifier.dart';

import '../../support/builders.dart';
import '../../support/real_translations.dart';

const _teamNames = {'real': 'Real Madrid', 'arsenal': 'Arsenal'};

EventModel _upcomingEvent(String id, String name) => eventOf(
      id: id,
      name: name,
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 30)),
    );

/// Lo que ve el jugador en general: el evento del Real Madrid, que no debe aparecer cuando mira a otro equipo.
class _FakeEventsSearchService extends EventsSearchService {
  @override
  Future<EventsPage> search({String? text, EventStatus? status, int page = 0, int? size}) async => EventsPage(
        events: [_upcomingEvent('champions', 'Uefa Champions League')],
        page: 0,
        totalPages: 1,
        totalElements: 1,
      );
}

/// Los eventos en que juega cada equipo; un equipo que no está en el mapa no juega ninguno.
class _FakeTeamEventsService extends TeamEventsService {
  final Map<String, List<EventModel>> eventsByTeam;

  _FakeTeamEventsService(this.eventsByTeam);

  @override
  Future<List<EventModel>> getOfMatches(Iterable<MatchModel> matches, String teamId) async =>
      eventsByTeam[teamId] ?? const [];
}

/// Los partidos de todos los equipos del jugador: un próximo partido del Real Madrid (en la Champions) y otro del Arsenal
/// (en la Premier). El evento de un equipo es el de sus partidos.
class _FakeMatchesService extends MatchesService {
  @override
  Future<List<MatchModel>> getMine() async => [
        matchOf(
          id: 'real-match',
          eventId: 'champions',
          homeTeamId: 'real',
          awayTeamId: 'barca',
          homeTeamName: 'Real Madrid',
          awayTeamName: 'Barcelona FC',
          date: DateTime.now().add(const Duration(days: 3)),
        ),
        matchOf(
          id: 'arsenal-match',
          eventId: 'premier',
          homeTeamId: 'arsenal',
          awayTeamId: 'chelsea',
          homeTeamName: 'Arsenal',
          awayTeamName: 'Chelsea FC',
          date: DateTime.now().add(const Duration(days: 4)),
        ),
      ];
}

class _FakeTeamsService extends TeamsService {
  @override
  Future<TeamModel?> getById(String id) async => TeamModel(id: id, name: _teamNames[id] ?? id);
}

class _FakePlayersService extends PlayersService {
  @override
  Future<PlayerModel?> getCurrent() async => const PlayerModel(
        id: 'ana',
        firstName: 'Ana',
        lastName: 'Pérez',
        email: 'ana@email.com',
        teamId: 'real',
        teamName: 'Real Madrid',
        teams: [
          PlayerTeam(teamId: 'real', teamName: 'Real Madrid'),
          PlayerTeam(teamId: 'arsenal', teamName: 'Arsenal'),
        ],
      );
}

/// `flutter_test` dibuja el texto con la fuente Ahem (casi el doble de ancha que Roboto): el marcador del próximo partido
/// «se desborda» solo aquí. Estos tests miran qué datos se muestran, no si caben, así que ese aviso se ignora; cualquier
/// otro error sigue fallando el test.
void _ignoreOverflowsCausedByTheTestFont() {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    original?.call(details);
  };
  addTearDown(() => FlutterError.onError = original);
}

Future<void> _openHome(WidgetTester tester, {Map<String, List<EventModel>>? eventsByTeam}) async {
  _ignoreOverflowsCausedByTheTestFont();
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  getIt.registerSingleton<EventsSearchService>(_FakeEventsSearchService());
  getIt.registerSingleton<TeamEventsService>(
    _FakeTeamEventsService(
      eventsByTeam ??
          {
            'real': [_upcomingEvent('champions', 'Uefa Champions League')],
            'arsenal': [_upcomingEvent('premier', 'Premier League')],
          },
    ),
  );
  getIt.registerSingleton<MatchesService>(_FakeMatchesService());
  getIt.registerSingleton<TeamsService>(_FakeTeamsService());
  getIt.registerSingleton<PlayersService>(_FakePlayersService());
  getIt.registerSingleton<ActiveTeamNotifier>(ActiveTeamNotifier());
  getIt.registerSingleton<EmailVerificationNotifier>(EmailVerificationNotifier(AccountService()));
  getIt.registerSingleton<InvitationsNotifier>(
    InvitationsNotifier(TeamInvitationsService(), SessionService(resetSessionScopedState: () {})),
  );
  await pumpWithRealTranslations(
    tester,
    home: (_) => Scaffold(
      body: HomeTab(
        menuStyle: HomeMenuStyle.drawer,
        menuItems: const [],
        isLoadingMenu: false,
        menuError: false,
        onRetryMenu: () {},
        onToggleMenuStyle: () {},
      ),
    ),
  );
  await _pumpFrames(tester);
}

/// Avanza la pantalla alternando fotogramas con turnos del bucle real: la lectura nace en `initState`, que
/// `pumpWithRealTranslations` ejecuta en la zona de tiempo real, y `pumpAndSettle` no se la espera.
Future<void> _pumpFrames(WidgetTester tester, {int frames = 10}) async {
  for (var i = 0; i < frames; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Abre la hoja del indicador de equipo y elige [teamId].
Future<void> _switchTeamFromThePill(WidgetTester tester, String teamId) async {
  await tester.tap(find.descendant(of: find.byType(ActiveTeamPill), matching: find.byType(InkWell)));
  await _pumpFrames(tester);
  await tester.tap(find.byKey(ValueKey('team-option-$teamId')));
  await _pumpFrames(tester);
}

void main() {
  setUpAll(initRealTranslations);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(getIt.reset);

  testWidgets('abre con la información del equipo activo (el último al que entró)', (tester) async {
    await _openHome(tester);

    expect(find.text('Barcelona FC'), findsOneWidget);
    expect(find.text('Chelsea FC'), findsNothing);
  });

  testWidgets('al elegir otro equipo en el indicador, el inicio muestra la información de ese equipo', (tester) async {
    await _openHome(tester);

    await _switchTeamFromThePill(tester, 'arsenal');

    // El próximo partido y «Tu equipo» son los del Arsenal; nada del Real Madrid queda en pantalla.
    expect(find.text('Chelsea FC'), findsOneWidget);
    expect(find.text('Barcelona FC'), findsNothing);
    expect(find.text('Real Madrid'), findsNothing);
    expect(find.text('Arsenal'), findsWidgets);
  });

  testWidgets('el próximo evento es el del equipo activo y cambia con él', (tester) async {
    await _openHome(tester);

    // El nombre del evento también va sobre el marcador del próximo partido: por eso «al menos uno».
    expect(find.text('Uefa Champions League'), findsWidgets);
    expect(find.text('Premier League'), findsNothing);

    await _switchTeamFromThePill(tester, 'arsenal');

    expect(find.text('Premier League'), findsWidgets);
    expect(find.text('Uefa Champions League'), findsNothing);
  });

  testWidgets('si el equipo elegido no juega ningún evento no muestra el de otro equipo', (tester) async {
    await _openHome(tester, eventsByTeam: {'real': [_upcomingEvent('champions', 'Uefa Champions League')]});

    await _switchTeamFromThePill(tester, 'arsenal');

    expect(find.text('Uefa Champions League'), findsNothing);
    expect(find.text('Sin eventos próximos'), findsOneWidget);
  });

  testWidgets('volver a elegir el equipo anterior vuelve a mostrar su información', (tester) async {
    await _openHome(tester);

    await _switchTeamFromThePill(tester, 'arsenal');
    await _switchTeamFromThePill(tester, 'real');

    expect(find.text('Barcelona FC'), findsOneWidget);
    expect(find.text('Chelsea FC'), findsNothing);
  });
}
