import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/courts_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/teams_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/court_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/team_model.dart';
import 'package:sport_platform/modules/events/shared/data/datasource/events_catalog_service.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/matches/data/datasource/matches_service.dart';
import 'package:sport_platform/modules/matches/presentation/providers/matches_notifier.dart';

import '../../support/builders.dart';

class _FakeMatchesService extends MatchesService {
  List<MatchModel> mine = [];
  List<MatchModel> all = [];
  bool failMine = false;
  int allCalls = 0;

  @override
  Future<List<MatchModel>> getMine() async {
    if (failMine) throw Exception('sin red');
    return mine;
  }

  @override
  Future<List<MatchModel>> getAll() async {
    allCalls++;
    return all;
  }
}

class _FakeEventsService extends EventsCatalogService {
  @override
  Future<List<EventModel>> getAll() async => [
    eventOf(
      name: 'Liga de barrio',
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 12, 1),
    ),
  ];
}

class _FakeTeamsService extends TeamsService {
  @override
  Future<List<TeamModel>> getAll() async => const [
    TeamModel(id: 'home', name: 'Tigres'),
    TeamModel(id: 'away', name: 'Leones'),
  ];
}

class _FakeCourtsService extends CourtsService {
  @override
  Future<List<CourtModel>> getAll() async => const [];
}

void main() {
  late _FakeMatchesService matchesService;
  late MatchesNotifier notifier;

  setUp(() {
    matchesService = _FakeMatchesService();
    notifier = MatchesNotifier(
      matchesService: matchesService,
      eventsService: _FakeEventsService(),
      teamsService: _FakeTeamsService(),
      courtsService: _FakeCourtsService(),
    );
  });

  tearDown(() => notifier.dispose());

  test(
    'abre con los partidos de su equipo y no descarga todos los de la plataforma',
    () async {
      matchesService.mine = [
        matchOf(id: 'mine-1', date: DateTime(2026, 11, 1)),
      ];
      matchesService.all = [
        matchOf(id: 'a', date: DateTime(2026, 11, 2)),
        matchOf(id: 'b', date: DateTime(2026, 11, 3)),
      ];

      await notifier.load();

      expect(notifier.scope, MatchesScope.mine);
      expect(notifier.visibleMatches.map((match) => match.id), ['mine-1']);
      expect(matchesService.allCalls, 0);
    },
  );

  test('sin partidos de su equipo abre directamente con todos', () async {
    matchesService.mine = [];
    matchesService.all = [matchOf(id: 'a', date: DateTime(2026, 11, 1))];

    await notifier.load();

    expect(notifier.scope, MatchesScope.all);
    expect(notifier.visibleMatches.map((match) => match.id), ['a']);
    expect(notifier.hasNoMatchesOfMyTeam, isTrue);
  });

  test(
    'descarga todos los partidos solo la primera vez que se piden',
    () async {
      matchesService.mine = [
        matchOf(id: 'mine-1', date: DateTime(2026, 11, 1)),
      ];
      matchesService.all = [matchOf(id: 'a', date: DateTime(2026, 11, 2))];
      await notifier.load();

      await notifier.selectScope(MatchesScope.all);
      await notifier.selectScope(MatchesScope.mine);
      await notifier.selectScope(MatchesScope.all);

      expect(matchesService.allCalls, 1);
      expect(notifier.visibleMatches.map((match) => match.id), ['a']);
    },
  );

  test(
    'recargar vuelve a pedir todos los partidos si se estaba mirando todos',
    () async {
      matchesService.mine = [];
      matchesService.all = [matchOf(id: 'a', date: DateTime(2026, 11, 1))];
      await notifier.load();

      await notifier.load();

      expect(matchesService.allCalls, 2);
    },
  );

  test('si falla la carga guarda la clave de traducción del error', () async {
    matchesService.failMine = true;

    await notifier.load();

    expect(notifier.error, 'mobile.matches.load_error');
    expect(notifier.loading, isFalse);
  });

  test(
    'traduce los ids a nombres y deja un guion si no conoce al equipo',
    () async {
      await notifier.load();

      expect(notifier.teamName('home'), 'Tigres');
      expect(notifier.teamName('desconocido'), '—');
      expect(notifier.eventName('event-1'), 'Liga de barrio');
      expect(notifier.eventName('otro'), '');
      expect(notifier.courtName(null), isNull);
    },
  );
}
