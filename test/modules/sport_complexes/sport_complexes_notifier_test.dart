import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/courts_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/court_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/events/shared/data/datasource/team_events_service.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/sport_complexes/data/datasource/sport_complexes_service.dart';
import 'package:sport_platform/modules/sport_complexes/data/models/sport_complex_model.dart';
import 'package:sport_platform/modules/sport_complexes/presentation/providers/sport_complexes_notifier.dart';
import 'package:sport_platform/modules/teams/presentation/providers/active_team_notifier.dart';

import '../../support/builders.dart';

class _FakeComplexesService extends SportComplexesService {
  int reads = 0;
  bool fail = false;

  @override
  Future<List<SportComplexModel>> getAll() async {
    reads++;
    if (fail) throw Exception('sin red');
    return const [
      SportComplexModel(id: 'norte', name: 'Complejo Norte'),
      SportComplexModel(id: 'sur', name: 'Complejo Sur'),
      SportComplexModel(id: 'este', name: 'Complejo Este'),
    ];
  }
}

class _FakeCourtsService extends CourtsService {
  @override
  Future<List<CourtModel>> getAll() async => const [
        CourtModel(id: 'k1', name: 'Cancha 1', sportComplexId: 'norte'),
        CourtModel(id: 'k2', name: 'Cancha 2', sportComplexId: 'norte'),
        CourtModel(id: 'k3', name: 'Cancha A', sportComplexId: 'sur'),
        CourtModel(id: 'k4', name: 'Cancha suelta'),
      ];
}

/// Los eventos de cada equipo (con los complejos donde se juegan) y qué equipos se pidieron.
class _FakeTeamEventsService extends TeamEventsService {
  final Map<String, List<EventModel>> eventsByTeam;
  final List<String> requests = [];
  bool fail = false;

  _FakeTeamEventsService(this.eventsByTeam);

  @override
  Future<List<EventModel>> getOfTeam(String teamId) async {
    requests.add(teamId);
    if (fail) throw Exception('sin red');
    return eventsByTeam[teamId] ?? const [];
  }
}

class _FakePlayersService extends PlayersService {
  PlayerModel? player;
  bool fail = false;

  @override
  Future<PlayerModel?> getCurrent() async {
    if (fail) throw Exception('sin red');
    return player;
  }
}

/// Ana juega en dos equipos: «home» (el último al que entró, el activo al abrir) y «other».
const _inTwoTeams = PlayerModel(
  id: 'ana',
  firstName: 'Ana',
  lastName: 'Pérez',
  email: 'ana@email.com',
  teamId: 'home',
  teamName: 'Tigres',
  teams: [
    PlayerTeam(teamId: 'home', teamName: 'Tigres'),
    PlayerTeam(teamId: 'other', teamName: 'Pumas'),
  ],
);

EventModel _event(String id, List<String> complexIds) =>
    eventOf(id: id, startDate: DateTime(2026, 1, 1), endDate: DateTime(2026, 12, 1), sportComplexIds: complexIds);

void main() {
  late _FakeComplexesService complexes;
  late _FakeTeamEventsService teamEvents;
  late _FakePlayersService players;
  late ActiveTeamNotifier activeTeam;
  late SportComplexesNotifier notifier;

  List<String> complexNames() => notifier.overviews.map((overview) => overview.complex.name).toList();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    complexes = _FakeComplexesService();
    teamEvents = _FakeTeamEventsService({
      // Tigres juega dos eventos: uno en el Norte y otro en el Norte y el Sur. Pumas, uno en el Este.
      'home': [_event('liga', ['norte']), _event('copa', ['norte', 'sur'])],
      'other': [_event('torneo', ['este'])],
    });
    players = _FakePlayersService()..player = _inTwoTeams;
    activeTeam = ActiveTeamNotifier();
    notifier = SportComplexesNotifier(
      complexesService: complexes,
      courtsService: _FakeCourtsService(),
      teamEventsService: teamEvents,
      playersService: players,
      activeTeam: activeTeam,
    );
  });

  tearDown(() => notifier.dispose());

  test('abre con los complejos de los eventos del equipo activo, cada uno con sus canchas', () async {
    await notifier.load();

    expect(notifier.scope, ComplexesScope.myTeam);
    expect(notifier.hasTeam, isTrue);
    expect(complexNames(), ['Complejo Norte', 'Complejo Sur']);
    expect(notifier.overviews.first.courts.map((court) => court.name), ['Cancha 1', 'Cancha 2']);
    expect(teamEvents.requests, ['home']);
    expect(notifier.error, isNull);
    expect(notifier.loading, isFalse);
  });

  test('en «Mi equipo» no hay canchas sin complejo: ningún evento las tiene asignadas', () async {
    await notifier.load();

    expect(notifier.courtsWithoutComplex, isEmpty);
  });

  test('«Todos» muestra todos los complejos y las canchas sin complejo, sin volver a leer el catálogo', () async {
    await notifier.load();

    await notifier.selectScope(ComplexesScope.all);

    expect(complexNames(), ['Complejo Este', 'Complejo Norte', 'Complejo Sur']);
    expect(notifier.courtsWithoutComplex.map((court) => court.name), ['Cancha suelta']);
    expect(complexes.reads, 1);

    await notifier.selectScope(ComplexesScope.myTeam);
    expect(complexNames(), ['Complejo Norte', 'Complejo Sur']);
    expect(teamEvents.requests, ['home']);
  });

  test('al elegir otro equipo en la app se muestran los complejos de sus eventos', () async {
    await notifier.load();

    activeTeam.select('other');
    await pumpEventQueue();

    expect(notifier.scope, ComplexesScope.myTeam);
    expect(complexNames(), ['Complejo Este']);
    expect(notifier.overviews.single.courts, isEmpty);
    expect(teamEvents.requests, ['home', 'other']);
    expect(complexes.reads, 1);
  });

  test('volver a un equipo ya leído no vuelve a pedir sus eventos', () async {
    await notifier.load();
    activeTeam.select('other');
    await pumpEventQueue();

    activeTeam.select('home');
    await pumpEventQueue();

    expect(complexNames(), ['Complejo Norte', 'Complejo Sur']);
    expect(teamEvents.requests, ['home', 'other']);
  });

  test('en «Todos» cambiar de equipo no recarga nada', () async {
    await notifier.load();
    await notifier.selectScope(ComplexesScope.all);

    activeTeam.select('other');
    await pumpEventQueue();

    expect(notifier.scope, ComplexesScope.all);
    expect(teamEvents.requests, ['home']);
  });

  test('un equipo cuyos eventos no tienen complejos queda sin ninguno, en vez de mostrar los de otros', () async {
    teamEvents.eventsByTeam['home']!.clear();

    await notifier.load();

    expect(notifier.scope, ComplexesScope.myTeam);
    expect(notifier.overviews, isEmpty);
    expect(notifier.error, isNull);
  });

  test('actualizar conserva el alcance elegido y vuelve a leer todo', () async {
    await notifier.load();
    await notifier.selectScope(ComplexesScope.all);

    await notifier.load();
    expect(notifier.scope, ComplexesScope.all);
    expect(complexes.reads, 2);

    await notifier.selectScope(ComplexesScope.myTeam);
    expect(teamEvents.requests, ['home', 'home']);
  });

  test('quien aún no tiene equipo abre con todos los complejos y no puede elegir «Mi equipo»', () async {
    players.player = null;

    await notifier.load();

    expect(notifier.hasTeam, isFalse);
    expect(notifier.scope, ComplexesScope.all);
    expect(complexNames(), ['Complejo Este', 'Complejo Norte', 'Complejo Sur']);

    await notifier.selectScope(ComplexesScope.myTeam);
    expect(notifier.scope, ComplexesScope.all);
    expect(teamEvents.requests, isEmpty);
  });

  test('si no se puede leer al jugador abre con todos los complejos en vez de quedar en blanco', () async {
    players.fail = true;

    await notifier.load();

    expect(notifier.scope, ComplexesScope.all);
    expect(complexNames(), hasLength(3));
  });

  test('si falla la lectura de los complejos guarda la clave del error', () async {
    complexes.fail = true;

    await notifier.load();

    expect(notifier.error, 'mobile.complexes.load_error');
    expect(notifier.hasNothingYet, isTrue);
    expect(notifier.loading, isFalse);
  });

  test('si falla la lectura de los eventos del equipo guarda la clave del error', () async {
    teamEvents.fail = true;

    await notifier.load();

    expect(notifier.error, 'mobile.complexes.load_error');
    expect(notifier.loading, isFalse);
  });
}
