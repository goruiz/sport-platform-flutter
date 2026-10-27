import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/team_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/enums/match_status.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/home/data/datasource/home_dashboard_service.dart';

import '../../support/builders.dart';

void main() {
  final now = DateTime(2026, 10, 27, 12);

  HomeDashboardData dataOf({
    List<EventModel> events = const [],
    List<MatchModel> matches = const [],
  }) => HomeDashboardData(
    events: events,
    matches: matches,
    teams: const [
      TeamModel(id: 'home', name: 'Tigres'),
      TeamModel(id: 'away', name: 'Leones'),
    ],
    currentPlayer: null,
  );

  group('nextEvent', () {
    final early = eventOf(
      id: 'early',
      startDate: DateTime(2026, 10, 1),
      endDate: DateTime(2026, 12, 1),
    );
    final late = eventOf(
      id: 'late',
      startDate: DateTime(2026, 11, 1),
      endDate: DateTime(2026, 12, 1),
    );

    test('sin partidos propios es el evento que empieza antes de todos', () {
      expect(dataOf(events: [late, early]).nextEvent(now)?.id, 'early');
    });

    test(
      'si el equipo juega en un evento, ese tiene prioridad aunque empiece después',
      () {
        final mine = matchOf(
          eventId: 'late',
          date: now.add(const Duration(days: 2)),
        );

        expect(
          dataOf(events: [early, late], matches: [mine]).nextEvent(now)?.id,
          'late',
        );
      },
    );

    test('no cuenta un evento cancelado ni uno que ya terminó', () {
      final cancelled = eventOf(
        id: 'c',
        status: 'CANCELLED',
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 12, 1),
      );
      final over = eventOf(
        id: 'o',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 10, 26),
      );

      expect(dataOf(events: [cancelled, over]).nextEvent(now), isNull);
    });

    test('un evento que termina hoy todavía cuenta', () {
      final endsToday = eventOf(
        id: 't',
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 10, 27),
      );

      expect(dataOf(events: [endsToday]).nextEvent(now)?.id, 't');
    });
  });

  group('nextMatch', () {
    test('es el partido futuro más cercano del equipo', () {
      final sooner = matchOf(
        id: 'sooner',
        date: now.add(const Duration(days: 1)),
      );
      final later = matchOf(
        id: 'later',
        date: now.add(const Duration(days: 9)),
      );

      expect(dataOf(matches: [later, sooner]).nextMatch(now)?.id, 'sooner');
    });

    test('sin partidos futuros es null', () {
      final past = matchOf(date: now.subtract(const Duration(days: 1)));

      expect(dataOf(matches: [past]).nextMatch(now), isNull);
    });
  });

  group('latestResult', () {
    test('es el último partido jugado con resultado', () {
      final older = matchOf(
        id: 'older',
        date: DateTime(2026, 9, 1),
        homeScore: 1,
        awayScore: 0,
      );
      final newer = matchOf(
        id: 'newer',
        date: DateTime(2026, 10, 20),
        homeScore: 2,
        awayScore: 2,
      );

      expect(dataOf(matches: [older, newer]).latestResult(now)?.id, 'newer');
    });

    test('ignora uno cancelado aunque traiga marcador', () {
      final cancelled = matchOf(
        date: DateTime(2026, 10, 20),
        status: MatchStatus.cancelled,
        homeScore: 1,
        awayScore: 0,
      );

      expect(dataOf(matches: [cancelled]).latestResult(now), isNull);
    });
  });

  test('teamName deja un guion si no conoce al equipo', () {
    final data = dataOf();

    expect(data.teamName('home'), 'Tigres');
    expect(data.teamName('nadie'), '—');
  });
}
