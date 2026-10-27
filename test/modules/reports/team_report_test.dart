import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/reports/domain/team_report.dart';

import '../../support/builders.dart';

void main() {
  const myTeam = 'mine';

  // Mi equipo como local ganando 3-1, como visitante empatando 2-2 y como visitante perdiendo 0-1.
  final matches = [
    matchOf(
      id: 'm1',
      homeTeamId: myTeam,
      awayTeamId: 'x',
      date: DateTime(2026, 9, 1),
      homeScore: 3,
      awayScore: 1,
    ),
    matchOf(
      id: 'm2',
      homeTeamId: 'y',
      awayTeamId: myTeam,
      date: DateTime(2026, 9, 8),
      homeScore: 2,
      awayScore: 2,
      eventId: 'event-2',
    ),
    matchOf(
      id: 'm3',
      homeTeamId: 'z',
      awayTeamId: myTeam,
      date: DateTime(2026, 9, 15),
      homeScore: 1,
      awayScore: 0,
    ),
    matchOf(
      id: 'm4',
      homeTeamId: myTeam,
      awayTeamId: 'x',
      date: DateTime(2026, 9, 22),
    ),
  ];

  group('resultFor', () {
    test('como local, ganar con más goles', () {
      expect(resultFor(myTeam, matches[0]), MatchResult.win);
    });

    test('como visitante, empatar', () {
      expect(resultFor(myTeam, matches[1]), MatchResult.draw);
    });

    test('como visitante, perder con menos goles', () {
      expect(resultFor(myTeam, matches[2]), MatchResult.loss);
    });

    test(
      'un partido sin resultado, o que el equipo no jugó, no tiene resultado',
      () {
        expect(resultFor(myTeam, matches[3]), isNull);
        expect(resultFor('otro', matches[0]), isNull);
      },
    );
  });

  group('buildTeamRecord', () {
    test(
      'suma partidos, goles a favor y en contra de los que tienen resultado',
      () {
        final record = buildTeamRecord(myTeam, matches);

        expect(record.played, 3);
        expect((record.won, record.drawn, record.lost), (1, 1, 1));
        expect(record.goalsFor, 5);
        expect(record.goalsAgainst, 4);
        expect(record.goalDifference, 1);
      },
    );

    test('sin partidos jugados el balance está vacío y no divide por cero', () {
      final record = buildTeamRecord(myTeam, [matches[3]]);

      expect(record.isEmpty, isTrue);
      expect(record.winRate, 0);
    });

    test('la proporción de victorias es ganados entre jugados', () {
      expect(buildTeamRecord(myTeam, matches).winRate, closeTo(1 / 3, 0.0001));
    });
  });

  group('buildRecordsByEvent', () {
    test('separa el balance por evento y omite los eventos sin resultados', () {
      final byEvent = buildRecordsByEvent(myTeam, matches);

      expect(byEvent.keys, unorderedEquals(['event-1', 'event-2']));
      expect(byEvent['event-1']!.played, 2);
      expect(byEvent['event-2']!.drawn, 1);
    });
  });

  group('buildRecentForm', () {
    test('devuelve los últimos resultados del más viejo al más reciente', () {
      final form = buildRecentForm(myTeam, matches, limit: 2);

      expect(form, [MatchResult.draw, MatchResult.loss]);
    });

    test('con un límite mayor devuelve todos los que hay', () {
      expect(buildRecentForm(myTeam, matches, limit: 10), hasLength(3));
    });
  });
}
