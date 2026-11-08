import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/courts_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/court_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/shared/data/datasource/events_search_service.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/event_status.dart';
import 'package:sport_platform/modules/matches/data/datasource/matches_service.dart';
import 'package:sport_platform/modules/matches/presentation/providers/matches_notifier.dart';

import '../../support/builders.dart';

class _FakeMatchesService extends MatchesService {
  List<MatchModel> mine = [];
  Map<String, List<MatchModel>> byEvent = {};
  bool failMine = false;
  final List<String> eventCalls = [];

  @override
  Future<List<MatchModel>> getMine() async {
    if (failMine) throw Exception('sin red');
    return mine;
  }

  @override
  Future<List<MatchModel>> getByEvent(String eventId) async {
    eventCalls.add(eventId);
    return byEvent[eventId] ?? [];
  }
}

class _FakeEventsSearchService extends EventsSearchService {
  int searches = 0;

  @override
  Future<EventsPage> search({String? text, EventStatus? status, int page = 0, int? size}) async {
    searches++;
    return EventsPage(
      events: [
        eventOf(id: 'event-1', name: 'Liga de barrio', startDate: DateTime(2026, 1, 1), endDate: DateTime(2026, 12, 1)),
        eventOf(id: 'event-2', name: 'Copa', startDate: DateTime(2026, 2, 1), endDate: DateTime(2026, 3, 1)),
      ],
      page: 0,
      totalPages: 1,
      totalElements: 2,
    );
  }
}

class _FakeCourtsService extends CourtsService {
  @override
  Future<List<CourtModel>> getAll() async => const [];
}

void main() {
  late _FakeMatchesService matchesService;
  late _FakeEventsSearchService eventsSearchService;
  late MatchesNotifier notifier;

  setUp(() {
    matchesService = _FakeMatchesService();
    eventsSearchService = _FakeEventsSearchService();
    notifier = MatchesNotifier(
      matchesService: matchesService,
      eventsSearchService: eventsSearchService,
      courtsService: _FakeCourtsService(),
    );
  });

  tearDown(() => notifier.dispose());

  test('abre con los partidos de su equipo y no lee los de ningún evento', () async {
    matchesService.mine = [matchOf(id: 'mine-1', date: DateTime(2026, 11, 1))];

    await notifier.load();

    expect(notifier.scope, MatchesScope.mine);
    expect(notifier.visibleMatches.map((match) => match.id), ['mine-1']);
    expect(matchesService.eventCalls, isEmpty);
    expect(eventsSearchService.searches, 0);
  });

  test('sin partidos de su equipo abre con los del primer evento que ofrece el backend', () async {
    matchesService.mine = [];
    matchesService.byEvent = {
      'event-1': [matchOf(id: 'a', date: DateTime(2026, 11, 1))],
    };

    await notifier.load();

    expect(notifier.scope, MatchesScope.all);
    expect(notifier.selectedEventId, 'event-1');
    expect(notifier.visibleMatches.map((match) => match.id), ['a']);
    expect(notifier.hasNoMatchesOfMyTeam, isTrue);
  });

  test('«todos» lee los partidos de un evento a la vez y no repite lo que ya leyó', () async {
    matchesService.mine = [matchOf(id: 'mine-1', date: DateTime(2026, 11, 1))];
    matchesService.byEvent = {
      'event-1': [matchOf(id: 'a', date: DateTime(2026, 11, 2))],
      'event-2': [matchOf(id: 'b', date: DateTime(2026, 11, 3), eventId: 'event-2')],
    };
    await notifier.load();

    await notifier.selectScope(MatchesScope.all);
    await notifier.selectEvent('event-2');
    await notifier.selectEvent('event-1');
    await notifier.selectScope(MatchesScope.mine);
    await notifier.selectScope(MatchesScope.all);

    expect(matchesService.eventCalls, ['event-1', 'event-2']);
    expect(eventsSearchService.searches, 1);
    expect(notifier.visibleMatches.map((match) => match.id), ['a']);
    expect(notifier.eventOptions.map((event) => event.id), ['event-1', 'event-2']);
  });

  test('recargar descarta lo leído y vuelve a pedir el evento que se estaba mirando', () async {
    matchesService.mine = [];
    matchesService.byEvent = {'event-1': [matchOf(id: 'a', date: DateTime(2026, 11, 1))]};
    await notifier.load();

    await notifier.load();

    expect(matchesService.eventCalls, ['event-1', 'event-1']);
  });

  test('si falla la carga guarda la clave de traducción del error', () async {
    matchesService.failMine = true;

    await notifier.load();

    expect(notifier.error, 'mobile.matches.load_error');
    expect(notifier.loading, isFalse);
  });

  test('toma los nombres del propio partido y deja un guion si el backend no los trae', () async {
    final named = matchOf(
      date: DateTime(2026, 11, 1),
      homeTeamName: 'Tigres',
      awayTeamName: 'Leones',
      eventName: 'Liga de barrio',
    );
    final unnamed = matchOf(date: DateTime(2026, 11, 1));

    expect(notifier.homeName(named), 'Tigres');
    expect(notifier.awayName(named), 'Leones');
    expect(notifier.eventNameOf(named), 'Liga de barrio');
    expect(notifier.homeName(unnamed), '—');
    expect(notifier.eventNameOf(unnamed), '');
    expect(notifier.courtName(null), isNull);
  });
}
