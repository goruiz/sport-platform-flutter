import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/enums/match_status.dart';
import 'package:sport_platform/modules/matches/domain/match_rules.dart';

import '../../support/builders.dart';

void main() {
  final now = DateTime(2026, 10, 27, 12);

  group('matchesOfTeam', () {
    final asHome = matchOf(id: 'home-game', homeTeamId: 'tigres', awayTeamId: 'x', date: DateTime(2026, 11, 1));
    final asAway = matchOf(id: 'away-game', homeTeamId: 'y', awayTeamId: 'tigres', date: DateTime(2026, 11, 2));
    final other = matchOf(id: 'other', homeTeamId: 'pumas', awayTeamId: 'z', date: DateTime(2026, 11, 3));

    test('deja los partidos en que juega el equipo, de local o de visitante', () {
      expect(matchesOfTeam([asHome, other, asAway], 'tigres').map((match) => match.id), ['home-game', 'away-game']);
    });

    test('sin equipo no hay ninguno', () {
      expect(matchesOfTeam([asHome, asAway], null), isEmpty);
      expect(matchesOfTeam([asHome, asAway], ''), isEmpty);
    });
  });

  group('eventIdsOfTeam', () {
    test('junta los eventos de los partidos del equipo, sin repetir y sin los de otros equipos', () {
      final matches = [
        matchOf(id: 'a', homeTeamId: 'tigres', awayTeamId: 'x', date: DateTime(2026, 11, 1), eventId: 'liga'),
        matchOf(id: 'b', homeTeamId: 'y', awayTeamId: 'tigres', date: DateTime(2026, 11, 2), eventId: 'liga'),
        matchOf(id: 'c', homeTeamId: 'tigres', awayTeamId: 'z', date: DateTime(2026, 11, 3), eventId: 'copa'),
        matchOf(id: 'd', homeTeamId: 'pumas', awayTeamId: 'z', date: DateTime(2026, 11, 4), eventId: 'otro'),
      ];

      expect(eventIdsOfTeam(matches, 'tigres'), {'liga', 'copa'});
    });

    test('sin equipo, o si el equipo no tiene partidos, no hay ninguno', () {
      final matches = [matchOf(homeTeamId: 'tigres', awayTeamId: 'x', date: DateTime(2026, 11, 1))];

      expect(eventIdsOfTeam(matches, null), isEmpty);
      expect(eventIdsOfTeam(matches, 'pumas'), isEmpty);
    });

    test('un partido sin evento no cuenta', () {
      final matches = [matchOf(homeTeamId: 'tigres', awayTeamId: 'x', date: DateTime(2026, 11, 1), eventId: '')];

      expect(eventIdsOfTeam(matches, 'tigres'), isEmpty);
    });
  });

  group('upcomingMatches', () {
    test('deja los partidos futuros, el más cercano primero', () {
      final later = matchOf(
        id: 'later',
        date: now.add(const Duration(days: 5)),
      );
      final sooner = matchOf(
        id: 'sooner',
        date: now.add(const Duration(days: 1)),
      );
      final past = matchOf(
        id: 'past',
        date: now.subtract(const Duration(days: 1)),
      );

      final result = upcomingMatches([later, past, sooner], now);

      expect(result.map((match) => match.id), ['sooner', 'later']);
    });

    test('no cuenta los cancelados', () {
      final cancelled = matchOf(
        date: now.add(const Duration(days: 1)),
        status: MatchStatus.cancelled,
      );

      expect(upcomingMatches([cancelled], now), isEmpty);
    });

    test('un aplazado futuro sí cuenta: se jugará más adelante', () {
      final postponed = matchOf(
        date: now.add(const Duration(days: 3)),
        status: MatchStatus.postponed,
      );

      expect(upcomingMatches([postponed], now), hasLength(1));
    });
  });

  group('playedMatches', () {
    test('deja solo los que tienen resultado, el más reciente primero', () {
      final older = matchOf(
        id: 'older',
        date: DateTime(2026, 9, 1),
        homeScore: 1,
        awayScore: 0,
      );
      final newer = matchOf(
        id: 'newer',
        date: DateTime(2026, 10, 1),
        homeScore: 2,
        awayScore: 2,
      );
      final noScore = matchOf(id: 'none', date: DateTime(2026, 10, 10));
      final halfScore = matchOf(
        id: 'half',
        date: DateTime(2026, 10, 12),
        homeScore: 1,
      );

      final result = playedMatches([older, noScore, halfScore, newer]);

      expect(result.map((match) => match.id), ['newer', 'older']);
    });
  });

  group('matchesInCalendarOrder', () {
    test('ordena del más antiguo al más reciente sin tocar la lista original', () {
      final first = matchOf(id: 'first', date: DateTime(2026, 9, 1));
      final second = matchOf(id: 'second', date: DateTime(2026, 10, 1));
      final third = matchOf(id: 'third', date: DateTime(2026, 11, 1));
      final original = [third, first, second];

      final result = matchesInCalendarOrder(original);

      expect(result.map((match) => match.id), ['first', 'second', 'third']);
      expect(original.map((match) => match.id), ['third', 'first', 'second']);
    });
  });
}
