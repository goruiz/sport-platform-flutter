import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_platform/core/constants/app_constants.dart';
import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/events/shared/data/datasource/events_search_service.dart';
import 'package:sport_platform/modules/events/shared/data/datasource/team_events_service.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/events/shared/data/providers/events_explorer_notifier.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/event_status.dart';
import 'package:sport_platform/modules/teams/presentation/providers/active_team_notifier.dart';

import '../../support/builders.dart';

/// Devuelve páginas de eventos y recuerda qué se le pidió; una búsqueda puede quedar en espera para probar el orden de
/// las respuestas.
class _FakeSearchService extends EventsSearchService {
  final List<({String? text, EventStatus? status, int page})> requests = [];
  final Map<String, Completer<EventsPage>> pending = {};
  bool fail = false;

  static EventModel _event(String id) =>
      eventOf(id: id, name: 'Evento $id', startDate: DateTime(2026, 1, 1), endDate: DateTime(2026, 2, 1));

  @override
  Future<EventsPage> search({String? text, EventStatus? status, int page = 0, int? size}) {
    requests.add((text: text, status: status, page: page));
    if (fail) return Future.error(Exception('sin red'));
    final waiting = pending[text ?? ''];
    if (waiting != null) return waiting.future;
    return Future.value(EventsPage(
      events: [_event('p$page-a'), _event('p$page-b')],
      page: page,
      totalPages: 3,
      totalElements: 6,
    ));
  }
}

/// Los eventos de cada equipo y qué equipos se pidieron.
class _FakeTeamEventsService extends TeamEventsService {
  final Map<String, List<EventModel>> eventsByTeam;
  final List<String> requests = [];
  bool fail = false;

  _FakeTeamEventsService([this.eventsByTeam = const {}]);

  @override
  Future<List<EventModel>> getOfTeam(String teamId) async {
    requests.add(teamId);
    if (fail) throw Exception('sin red');
    return eventsByTeam[teamId] ?? const [];
  }
}

/// El jugador de la cuenta; sin jugador (`null`) no tiene equipo.
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

EventsExplorerNotifier _notifierOf({
  required EventsSearchService search,
  required TeamEventsService teamEvents,
  required PlayersService players,
  required ActiveTeamNotifier activeTeam,
}) =>
    EventsExplorerNotifier(
      searchService: search,
      teamEventsService: teamEvents,
      playersService: players,
      activeTeam: activeTeam,
    );

void main() {
  _registerSearchServiceTests();

  late _FakeSearchService service;
  late EventsExplorerNotifier notifier;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = _FakeSearchService();
    // Sin jugador no hay equipo: la lista es la de todos los eventos que ve.
    notifier = _notifierOf(
      search: service,
      teamEvents: _FakeTeamEventsService(),
      players: _FakePlayersService(),
      activeTeam: ActiveTeamNotifier(),
    );
  });

  tearDown(() => notifier.dispose());

  group('con un equipo activo', () {
    late _FakeTeamEventsService teamEvents;
    late _FakePlayersService players;
    late ActiveTeamNotifier activeTeam;
    late EventsExplorerNotifier teamNotifier;

    EventModel teamEvent(String id, String name, {String status = 'ACTIVE'}) =>
        eventOf(id: id, name: name, status: status, startDate: DateTime(2026, 1, 1), endDate: DateTime(2026, 2, 1));

    setUp(() {
      teamEvents = _FakeTeamEventsService({
        'home': [teamEvent('liga', 'Liga de barrio'), teamEvent('copa', 'Copa Quito', status: 'FINISHED')],
        'other': [teamEvent('torneo', 'Torneo relámpago')],
      });
      players = _FakePlayersService()..player = _inTwoTeams;
      activeTeam = ActiveTeamNotifier();
      teamNotifier = _notifierOf(search: service, teamEvents: teamEvents, players: players, activeTeam: activeTeam);
    });

    tearDown(() => teamNotifier.dispose());

    test('abre con los eventos del equipo activo, sin pedirle nada a la búsqueda general', () async {
      await teamNotifier.load();

      expect(teamNotifier.scope, EventsScope.myTeam);
      expect(teamNotifier.hasTeam, isTrue);
      expect(teamNotifier.events.map((event) => event.id), ['liga', 'copa']);
      expect(teamNotifier.totalElements, 2);
      expect(teamNotifier.hasMore, isFalse);
      expect(teamEvents.requests, ['home']);
      expect(service.requests, isEmpty);
    });

    test('buscar y filtrar por estado trabaja sobre los eventos del equipo sin volver a leerlos', () async {
      await teamNotifier.load();

      await teamNotifier.search('quito');
      expect(teamNotifier.events.map((event) => event.id), ['copa']);

      await teamNotifier.selectStatus(EventStatus.active);
      expect(teamNotifier.events, isEmpty);
      expect(teamNotifier.isFiltering, isTrue);

      await teamNotifier.search('');
      expect(teamNotifier.events.map((event) => event.id), ['liga']);
      expect(teamEvents.requests, ['home']);
      expect(service.requests, isEmpty);
    });

    test('«Todos» pide la primera página al backend y volver a «Mi equipo» no vuelve a leer los del equipo', () async {
      await teamNotifier.load();

      await teamNotifier.selectScope(EventsScope.all);
      expect(teamNotifier.events.map((event) => event.id), ['p0-a', 'p0-b']);
      expect(teamNotifier.hasMore, isTrue);

      await teamNotifier.selectScope(EventsScope.myTeam);
      expect(teamNotifier.events.map((event) => event.id), ['liga', 'copa']);
      expect(teamEvents.requests, ['home']);
      expect(service.requests, hasLength(1));
    });

    test('al elegir otro equipo en la app se leen los eventos de ese equipo', () async {
      await teamNotifier.load();

      activeTeam.select('other');
      await pumpEventQueue();

      expect(teamNotifier.scope, EventsScope.myTeam);
      expect(teamNotifier.events.map((event) => event.id), ['torneo']);
      expect(teamEvents.requests, ['home', 'other']);
    });

    test('en «Todos» cambiar de equipo no recarga nada: la lista no depende del equipo', () async {
      await teamNotifier.load();
      await teamNotifier.selectScope(EventsScope.all);

      activeTeam.select('other');
      await pumpEventQueue();

      expect(teamNotifier.scope, EventsScope.all);
      expect(service.requests, hasLength(1));
      expect(teamEvents.requests, ['home']);
    });

    test('actualizar conserva el alcance elegido y vuelve a leer los eventos del equipo', () async {
      await teamNotifier.load();
      await teamNotifier.selectScope(EventsScope.all);

      await teamNotifier.load();
      expect(teamNotifier.scope, EventsScope.all);

      await teamNotifier.selectScope(EventsScope.myTeam);
      expect(teamEvents.requests, ['home', 'home']);
    });

    test('si falla la lectura de los eventos del equipo guarda la clave del error y deja la lista vacía', () async {
      teamEvents.fail = true;

      await teamNotifier.load();

      expect(teamNotifier.error, 'mobile.events.load_error');
      expect(teamNotifier.events, isEmpty);
      expect(teamNotifier.loading, isFalse);
    });

    test('un equipo sin eventos deja la lista vacía y sigue en «Mi equipo»', () async {
      teamEvents.eventsByTeam.clear();

      await teamNotifier.load();

      expect(teamNotifier.scope, EventsScope.myTeam);
      expect(teamNotifier.events, isEmpty);
      expect(teamNotifier.error, isNull);
    });

    test('si no se puede leer al jugador abre con todos los eventos en vez de quedar en blanco', () async {
      players.fail = true;

      await teamNotifier.load();

      expect(teamNotifier.hasTeam, isFalse);
      expect(teamNotifier.scope, EventsScope.all);
      expect(teamNotifier.events.map((event) => event.id), ['p0-a', 'p0-b']);
    });
  });

  test('quien aún no tiene equipo abre con todos los eventos y no puede elegir «Mi equipo»', () async {
    await notifier.load();

    expect(notifier.hasTeam, isFalse);
    expect(notifier.scope, EventsScope.all);

    await notifier.selectScope(EventsScope.myTeam);

    expect(notifier.scope, EventsScope.all);
    expect(service.requests, hasLength(1));
  });

  test('abre con la primera página y dice que quedan más', () async {
    await notifier.load();

    expect(notifier.events.map((event) => event.id), ['p0-a', 'p0-b']);
    expect(notifier.hasMore, isTrue);
    expect(notifier.totalElements, 6);
    expect(notifier.isFiltering, isFalse);
  });

  test('cargar más suma la página que sigue a las que ya hay', () async {
    await notifier.load();

    await notifier.loadMore();
    await notifier.loadMore();

    expect(notifier.events.map((event) => event.id), ['p0-a', 'p0-b', 'p1-a', 'p1-b', 'p2-a', 'p2-b']);
    expect(notifier.hasMore, isFalse);
    expect(service.requests.map((request) => request.page), [0, 1, 2]);
  });

  test('cuando ya están todos, cargar más no pide nada', () async {
    await notifier.load();
    await notifier.loadMore();
    await notifier.loadMore();

    await notifier.loadMore();

    expect(service.requests, hasLength(3));
  });

  test('buscar vuelve a la primera página con el texto y el estado elegidos', () async {
    await notifier.load();
    await notifier.loadMore();

    await notifier.search('copa quito');
    await notifier.selectStatus(EventStatus.active);

    expect(service.requests.last.text, 'copa quito');
    expect(service.requests.last.status, EventStatus.active);
    expect(service.requests.last.page, 0);
    expect(notifier.events.map((event) => event.id), ['p0-a', 'p0-b']);
    expect(notifier.isFiltering, isTrue);
  });

  test('repetir la misma búsqueda no vuelve a pedir nada', () async {
    await notifier.load();

    await notifier.search('');
    await notifier.selectStatus(null);

    expect(service.requests, hasLength(1));
  });

  test('una respuesta lenta de una búsqueda anterior no pisa a la más nueva', () async {
    await notifier.load();
    final slow = Completer<EventsPage>();
    service.pending['lenta'] = slow;

    final slowSearch = notifier.search('lenta');
    await notifier.search('rapida');
    slow.complete(EventsPage(
      events: [_FakeSearchService._event('vieja')],
      page: 0,
      totalPages: 1,
      totalElements: 1,
    ));
    await slowSearch;

    expect(notifier.text, 'rapida');
    expect(notifier.events.map((event) => event.id), ['p0-a', 'p0-b']);
  });

  test('si falla la carga guarda la clave del error y deja la lista vacía', () async {
    service.fail = true;

    await notifier.load();

    expect(notifier.error, 'mobile.events.load_error');
    expect(notifier.events, isEmpty);
    expect(notifier.loading, isFalse);
  });
}

/// Cliente que no sale a la red y responde una página fija, para probar lo que `EventsSearchService` pide y lee.
class _RecordingDioClient extends DioClient {
  Map<String, dynamic>? queryParams;
  final Map<String, dynamic> body;

  _RecordingDioClient(this.body);

  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) async {
    this.queryParams = queryParams;
    expect(path, ApiEndpoints.eventsSearch);
    return Response(requestOptions: RequestOptions(path: path), statusCode: 200, data: body);
  }
}

void _registerSearchServiceTests() {
  {
    group('EventsSearchService', () {
      const apiPage = {
        'success': true,
        'data': {
          'content': [
            {'id': 'e1', 'name': 'Copa', 'status': 'ACTIVE', 'startDate': '2026-12-01', 'endDate': '2026-12-20'},
          ],
          'page': 1,
          'size': 20,
          'totalElements': 41,
          'totalPages': 3,
        },
      };

      test('pide la página, el texto recortado y el estado en mayúsculas', () async {
        final client = _RecordingDioClient(apiPage);

        await EventsSearchService(client: client).search(text: '  copa  ', status: EventStatus.upcoming, page: 1, size: 10);

        expect(client.queryParams, {'page': 1, 'size': 10, 'search': 'copa', 'status': 'UPCOMING'});
      });

      test('sin tamaño pide el de AppConstants', () async {
        final client = _RecordingDioClient(apiPage);

        await EventsSearchService(client: client).search();

        expect(client.queryParams!['size'], AppConstants.listPageSize.value);
      });

      test('un texto en blanco y sin estado no se envía', () async {
        final client = _RecordingDioClient(apiPage);

        await EventsSearchService(client: client).search(text: '   ');

        expect(client.queryParams!.containsKey('search'), isFalse);
        expect(client.queryParams!.containsKey('status'), isFalse);
      });

      test('lee los eventos y dónde está la página en la lista completa', () async {
        final page = await EventsSearchService(client: _RecordingDioClient(apiPage)).search();

        expect(page.events.single.name, 'Copa');
        expect(page.page, 1);
        expect(page.totalPages, 3);
        expect(page.totalElements, 41);
        expect(page.hasMore, isTrue);
      });

      test('la última página dice que no hay más', () {
        final last = EventsPage.fromJson({'content': [], 'page': 2, 'totalPages': 3, 'totalElements': 41});

        expect(last.hasMore, isFalse);
      });
    });
  }
}
