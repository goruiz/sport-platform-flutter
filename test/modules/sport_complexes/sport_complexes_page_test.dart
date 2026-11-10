import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/courts_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/court_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/events/shared/data/datasource/team_events_service.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/sport_complexes/data/datasource/sport_complexes_service.dart';
import 'package:sport_platform/modules/sport_complexes/data/models/sport_complex_model.dart';
import 'package:sport_platform/modules/sport_complexes/presentation/pages/sport_complexes_page.dart';
import 'package:sport_platform/modules/sport_complexes/presentation/providers/sport_complexes_notifier.dart';
import 'package:sport_platform/modules/teams/presentation/providers/active_team_notifier.dart';
import 'package:sport_platform/modules/teams/presentation/widgets/active_team_pill.dart';

import '../../support/builders.dart';
import '../../support/real_translations.dart';

class _FakeComplexesService extends SportComplexesService {
  @override
  Future<List<SportComplexModel>> getAll() async => const [
        SportComplexModel(id: 'norte', name: 'Complejo Norte', location: 'Av. Principal'),
        SportComplexModel(id: 'sur', name: 'Complejo Sur'),
        SportComplexModel(id: 'este', name: 'Complejo Este'),
      ];
}

class _FakeCourtsService extends CourtsService {
  @override
  Future<List<CourtModel>> getAll() async => const [
        CourtModel(id: 'k1', name: 'Cancha Uno', sportComplexId: 'norte'),
        CourtModel(id: 'k2', name: 'Cancha Dos', sportComplexId: 'norte'),
        CourtModel(id: 'k3', name: 'Cancha Alfa', sportComplexId: 'sur'),
        CourtModel(id: 'k4', name: 'Cancha suelta'),
      ];
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

EventModel _event(String id, String name, List<String> complexIds) => eventOf(
      id: id,
      name: name,
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 12, 1),
      sportComplexIds: complexIds,
    );

const _menuItem = MenuItemModel(id: 'menu-complexes', name: 'Complejos');

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

/// Tigres juega la Liga en el Norte y la Copa en el Norte y el Sur; Pumas, un Torneo en el Este.
final _eventsByTeam = {
  'tigres': [_event('liga', 'Liga de Barrio', ['norte']), _event('copa', 'Copa Quito', ['norte', 'sur'])],
  'pumas': [_event('torneo', 'Torneo Relámpago', ['este'])],
};

/// `flutter_test` dibuja el texto con la fuente Ahem (casi el doble de ancha que Roboto): una fila puede «desbordarse» solo
/// aquí. Estos tests miran qué se muestra, no si cabe, así que ese aviso se ignora; cualquier otro error sigue fallando.
void _ignoreOverflowsCausedByTheTestFont() {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    original?.call(details);
  };
  addTearDown(() => FlutterError.onError = original);
}

Future<void> _openComplexes(
  WidgetTester tester, {
  required PlayerModel? player,
  Map<String, List<EventModel>>? eventsByTeam,
}) async {
  _ignoreOverflowsCausedByTheTestFont();
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  getIt.registerSingleton<SportComplexesService>(_FakeComplexesService());
  getIt.registerSingleton<CourtsService>(_FakeCourtsService());
  getIt.registerSingleton<TeamEventsService>(_FakeTeamEventsService(eventsByTeam ?? _eventsByTeam));
  getIt.registerSingleton<PlayersService>(_FakePlayersService(player));
  getIt.registerSingleton<ActiveTeamNotifier>(ActiveTeamNotifier());
  await pumpWithRealTranslations(tester, home: (_) => const SportComplexesPage(item: _menuItem));
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

Finder _scopeSegment(String label) =>
    find.descendant(of: find.byType(SegmentedButton<ComplexesScope>), matching: find.text(label));

void main() {
  setUpAll(initRealTranslations);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(getIt.reset);

  testWidgets('abre en «Mi equipo» organizado por evento: cada evento del equipo con sus complejos y canchas', (tester) async {
    await _openComplexes(tester, player: _playerIn([_tigres, _pumas]));

    expect(find.byType(SegmentedButton<ComplexesScope>), findsOneWidget);
    expect(find.byType(ActiveTeamPill), findsOneWidget);
    expect(find.text('Liga de Barrio'), findsOneWidget);
    expect(find.text('Copa Quito'), findsOneWidget);
    expect(find.text('Complejo Sur'), findsOneWidget);
    // El Norte es sede de los dos eventos: sale bajo cada uno, con sus canchas.
    expect(find.text('Complejo Norte'), findsNWidgets(2));
    expect(find.text('Cancha Uno'), findsNWidgets(2));
    expect(find.text('Cancha Dos'), findsNWidgets(2));
    expect(find.text('Cancha Alfa'), findsOneWidget);
    expect(find.text('Torneo Relámpago'), findsNothing);
    // Lo de otros equipos o sin evento no aparece.
    expect(find.text('Complejo Este'), findsNothing);
    expect(find.text('Cancha suelta'), findsNothing);
  });

  testWidgets('abre con el equipo que el jugador dejó elegido en «Equipo»', (tester) async {
    SharedPreferences.setMockInitialValues({'active_team_id': 'pumas'});

    await _openComplexes(tester, player: _playerIn([_tigres, _pumas]));

    expect(find.text('Torneo Relámpago'), findsOneWidget);
    expect(find.text('Complejo Este'), findsOneWidget);
    expect(find.text('Complejo Norte'), findsNothing);
  });

  testWidgets('cambiar de equipo desde la píldora muestra los complejos de los eventos del otro equipo', (tester) async {
    await _openComplexes(tester, player: _playerIn([_tigres, _pumas]));

    await tester.tap(find.descendant(of: find.byType(ActiveTeamPill), matching: find.byType(InkWell)));
    await _pumpFrames(tester);
    await tester.tap(find.byKey(const ValueKey('team-option-pumas')));
    await _pumpFrames(tester);

    expect(find.text('Torneo Relámpago'), findsOneWidget);
    expect(find.text('Complejo Este'), findsOneWidget);
    expect(find.text('Liga de Barrio'), findsNothing);
    expect(find.text('Complejo Norte'), findsNothing);
    expect(find.text('Complejo Sur'), findsNothing);
  });

  testWidgets('«Todos» muestra todos los complejos (sin repetir ni eventos) y las canchas sin complejo, y deja de mostrar el equipo', (tester) async {
    await _openComplexes(tester, player: _playerIn([_tigres, _pumas]));

    await tester.tap(_scopeSegment('Todos'));
    await _pumpFrames(tester);

    expect(find.text('Liga de Barrio'), findsNothing);
    expect(find.text('Complejo Este'), findsOneWidget);
    expect(find.text('Complejo Norte'), findsOneWidget);
    expect(find.text('Canchas sin complejo'), findsOneWidget);
    expect(find.text('Cancha suelta'), findsOneWidget);
    expect(find.byType(ActiveTeamPill), findsNothing);
  });

  testWidgets('si los eventos del equipo no tienen complejos lo dice y ofrece ver todos', (tester) async {
    await _openComplexes(tester, player: _playerIn([_tigres, _pumas]), eventsByTeam: {'tigres': [_event('liga', 'Liga de Barrio', const [])]});

    expect(find.text('Sin complejos para tu equipo'), findsOneWidget);
    expect(find.text('Complejo Norte'), findsNothing);

    await tester.tap(find.text('Ver todos los complejos'));
    await _pumpFrames(tester);

    expect(find.text('Complejo Norte'), findsOneWidget);
    expect(find.text('Sin complejos para tu equipo'), findsNothing);
  });

  testWidgets('la búsqueda deja los complejos que coinciden por su nombre o por una de sus canchas', (tester) async {
    await _openComplexes(tester, player: _playerIn([_tigres, _pumas]));

    await tester.enterText(find.byType(TextField), 'alfa');
    await _pumpFrames(tester);

    // Solo el Sur tiene la Cancha Alfa, y solo se queda el evento que se juega en él.
    expect(find.text('Complejo Sur'), findsOneWidget);
    expect(find.text('Copa Quito'), findsOneWidget);
    expect(find.text('Liga de Barrio'), findsNothing);
    expect(find.text('Complejo Norte'), findsNothing);

    // Si coincide el nombre de un evento, sale con todos sus complejos.
    await tester.enterText(find.byType(TextField), 'liga');
    await _pumpFrames(tester);

    expect(find.text('Liga de Barrio'), findsOneWidget);
    expect(find.text('Complejo Norte'), findsOneWidget);
    expect(find.text('Copa Quito'), findsNothing);

    await tester.enterText(find.byType(TextField), 'inexistente');
    await _pumpFrames(tester);

    expect(find.text('Sin resultados'), findsOneWidget);
  });

  testWidgets('quien aún no tiene equipo ve todos los complejos y no el selector', (tester) async {
    await _openComplexes(tester, player: null);

    expect(find.byType(SegmentedButton<ComplexesScope>), findsNothing);
    expect(find.byType(ActiveTeamPill), findsNothing);
    expect(find.text('Complejo Este'), findsOneWidget);
    expect(find.text('Cancha suelta'), findsOneWidget);
  });
}
