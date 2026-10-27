import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/enums/match_status.dart';
import 'package:sport_platform/modules/matches/domain/match_rules.dart';

import '../../support/builders.dart';

void main() {
  final now = DateTime(2026, 10, 27, 12);

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
}
