import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/events/presentation/pages/events_page.dart' as screen;
import 'package:sport_platform/modules/events/shared/data/datasource/events_search_service.dart';
import 'package:sport_platform/modules/events/shared/data/datasource/team_events_service.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/events/shared/data/providers/events_explorer_notifier.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/event_status.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/teams/presentation/providers/active_team_notifier.dart';
import 'package:sport_platform/modules/teams/presentation/widgets/active_team_pill.dart';

import '../../support/builders.dart';
import '../../support/real_translations.dart';

/// Lo que ve el jugador en general (la búsqueda del backend): un evento público de otra parte.
class _FakeEventsSearchService extends EventsSearchService {
  @override
  Future<EventsPage> search({String? text, EventStatus? status, int page = 0, int? size}) async =>
      EventsPage(events: [_event('publica', 'Copa pública')], page: 0, totalPages: 1, totalElements: 1);
}

class _FakeTeamEventsService extends TeamEventsService {
  final Map<String, List<EventModel>> eventsByTeam;

  _FakeTeamEventsService(this.eventsByTeam);

  @override
  Future<List<EventModel>> getOfTeam(String teamId) async => eventsByTeam[teamId] ?? const [];
}

class _FakePlayersService extends PlayersService {
  final PlayerModel? player;

  _FakePlayersService(this.player);

  @override
  Future<PlayerModel?> getCurrent() async => player;
}

EventModel _event(String id, String name) =>
    eventOf(id: id, name: name, startDate: DateTime(2026, 1, 1), endDate: DateTime(2026, 12, 1));

const _menuItem = MenuItemModel(id: 'menu-events', name: 'Eventos');

const _tigres = PlayerTeam(teamId: 'tigres', teamName: 'Tigres');
const _pumas = PlayerTeam(teamId: 'pumas', teamName: 'Pumas');

PlayerModel _playerIn(List<PlayerTeam> teams) => PlayerModel(
      id: 'ana',
      firstName: 'Ana',
      lastName: 'Pérez',
      email: 'ana@email.com',
      teamId: teams.first.teamId,
      teamName: teams.first.teamName,
      teams: teams,
    );

final _eventsByTeam = {
  'tigres': [_event('liga', 'Liga de barrio')],
  'pumas': [_event('torneo', 'Torneo relámpago')],
};

Future<void> _openEvents(
  WidgetTester tester, {
  required PlayerModel? player,
  Map<String, List<EventModel>>? eventsByTeam,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  getIt.registerSingleton<EventsSearchService>(_FakeEventsSearchService());
  getIt.registerSingleton<TeamEventsService>(_FakeTeamEventsService(eventsByTeam ?? _eventsByTeam));
  getIt.registerSingleton<PlayersService>(_FakePlayersService(player));
  getIt.registerSingleton<ActiveTeamNotifier>(ActiveTeamNotifier());
  await pumpWithRealTranslations(tester, home: (_) => const screen.EventsPage(item: _menuItem));
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

/// Un segmento del selector «Mi equipo / Todos» (el chip de estado «Todos» también existe, por eso se acota).
Finder _scopeSegment(String label) =>
    find.descendant(of: find.byType(SegmentedButton<EventsScope>), matching: find.text(label));

void main() {
  setUpAll(initRealTranslations);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(getIt.reset);

  testWidgets('con varios equipos abre en «Mi equipo»: el equipo activo y solo sus eventos', (tester) async {
    await _openEvents(tester, player: _playerIn([_tigres, _pumas]));

    expect(find.byType(SegmentedButton<EventsScope>), findsOneWidget);
    expect(find.byType(ActiveTeamPill), findsOneWidget);
    expect(find.text('Tigres'), findsOneWidget);
    expect(find.text('Liga de barrio'), findsOneWidget);
    expect(find.text('Torneo relámpago'), findsNothing);
    expect(find.text('Copa pública'), findsNothing);
  });

  testWidgets('abre con el equipo que el jugador dejó elegido en «Equipo», no con el último al que entró', (tester) async {
    SharedPreferences.setMockInitialValues({'active_team_id': 'pumas'});

    await _openEvents(tester, player: _playerIn([_tigres, _pumas]));

    expect(find.text('Pumas'), findsOneWidget);
    expect(find.text('Torneo relámpago'), findsOneWidget);
    expect(find.text('Liga de barrio'), findsNothing);
  });

  testWidgets('cambiar de equipo desde la píldora muestra los eventos del otro equipo', (tester) async {
    await _openEvents(tester, player: _playerIn([_tigres, _pumas]));

    await tester.tap(find.text('Tigres'));
    await _pumpFrames(tester);
    await tester.tap(find.byKey(const ValueKey('team-option-pumas')));
    await _pumpFrames(tester);

    expect(find.text('Torneo relámpago'), findsOneWidget);
    expect(find.text('Liga de barrio'), findsNothing);
    expect(find.text('Pumas'), findsOneWidget);
  });

  testWidgets('«Todos» muestra los eventos de la plataforma y deja de mostrar el equipo', (tester) async {
    await _openEvents(tester, player: _playerIn([_tigres, _pumas]));

    await tester.tap(_scopeSegment('Todos'));
    await _pumpFrames(tester);

    expect(find.text('Copa pública'), findsOneWidget);
    expect(find.text('Liga de barrio'), findsNothing);
    expect(find.byType(ActiveTeamPill), findsNothing);

    await tester.tap(_scopeSegment('Mi equipo'));
    await _pumpFrames(tester);

    expect(find.text('Liga de barrio'), findsOneWidget);
    expect(find.byType(ActiveTeamPill), findsOneWidget);
  });

  testWidgets('con un solo equipo no hay nada que cambiar: sin píldora, pero con «Mi equipo» y «Todos»', (tester) async {
    await _openEvents(tester, player: _playerIn([_tigres]));

    expect(find.byType(SegmentedButton<EventsScope>), findsOneWidget);
    expect(find.text('Tigres'), findsNothing);
    expect(find.text('Liga de barrio'), findsOneWidget);
  });

  testWidgets('si el equipo no juega ningún evento lo dice y ofrece ver todos', (tester) async {
    await _openEvents(tester, player: _playerIn([_tigres, _pumas]), eventsByTeam: const {});

    expect(find.text('Tu equipo aún no juega ningún evento'), findsOneWidget);
    expect(find.text('Copa pública'), findsNothing);

    await tester.tap(find.text('Ver todos los eventos'));
    await _pumpFrames(tester);

    expect(find.text('Copa pública'), findsOneWidget);
    expect(find.text('Tu equipo aún no juega ningún evento'), findsNothing);
  });

  testWidgets('quien aún no tiene equipo ve todos los eventos y no el selector', (tester) async {
    await _openEvents(tester, player: null);

    expect(find.byType(SegmentedButton<EventsScope>), findsNothing);
    expect(find.byType(ActiveTeamPill), findsNothing);
    expect(find.text('Copa pública'), findsOneWidget);
  });
}
