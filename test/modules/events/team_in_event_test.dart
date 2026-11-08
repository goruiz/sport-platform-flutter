import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/enums/match_status.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/team_in_event.dart';

import '../../support/builders.dart';

void main() {
  const team = 'mine';

  group('splitTeamMatches', () {
    test('reparte los partidos del equipo entre próximos (del más cercano) y resultados (del más reciente)', () {
      final matches = [
        matchOf(id: 'later', homeTeamId: team, date: DateTime(2026, 11, 20)),
        matchOf(id: 'sooner', awayTeamId: team, date: DateTime(2026, 11, 12)),
        matchOf(id: 'old', homeTeamId: team, date: DateTime(2026, 10, 1), homeScore: 1, awayScore: 0),
        matchOf(id: 'recent', awayTeamId: team, date: DateTime(2026, 10, 15), homeScore: 2, awayScore: 2),
      ];

      final split = splitTeamMatches(team, matches);

      expect(split.upcoming.map((match) => match.id), ['sooner', 'later']);
      expect(split.results.map((match) => match.id), ['recent', 'old']);
    });

    test('ignora los partidos de otros equipos', () {
      final matches = [
        matchOf(id: 'ajeno', homeTeamId: 'x', awayTeamId: 'y', date: DateTime(2026, 11, 12)),
      ];

      expect(splitTeamMatches(team, matches).isEmpty, isTrue);
    });

    test('un partido cancelado sin resultado no cuenta como próximo', () {
      final matches = [
        matchOf(id: 'cancelado', homeTeamId: team, date: DateTime(2026, 11, 12), status: MatchStatus.cancelled),
        matchOf(id: 'aplazado', homeTeamId: team, date: DateTime(2026, 11, 13), status: MatchStatus.postponed),
      ];

      final split = splitTeamMatches(team, matches);

      expect(split.upcoming.map((match) => match.id), ['aplazado']);
    });

    test('un partido con resultado va a los resultados aunque su estado no sea el de terminado', () {
      final matches = [
        matchOf(id: 'jugado', homeTeamId: team, date: DateTime(2026, 11, 1), homeScore: 0, awayScore: 3),
      ];

      expect(splitTeamMatches(team, matches).results, hasLength(1));
    });
  });
}
