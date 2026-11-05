import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/matches/domain/match_day_groups.dart';

import '../../support/builders.dart';

void main() {
  test('una lista vacía no tiene grupos', () {
    expect(groupMatchesByDay(const []), isEmpty);
  });

  test('los partidos del mismo día forman un grupo aunque tengan horas distintas', () {
    final groups = groupMatchesByDay([
      matchOf(id: 'a', date: DateTime(2026, 11, 7, 9, 0)),
      matchOf(id: 'b', date: DateTime(2026, 11, 7, 20, 30)),
    ]);

    expect(groups, hasLength(1));
    expect(groups.single.day, DateTime(2026, 11, 7));
    expect(groups.single.matches.map((m) => m.id), ['a', 'b']);
  });

  test('un día nuevo abre un grupo nuevo y se conserva el orden de llegada', () {
    final groups = groupMatchesByDay([
      matchOf(id: 'a', date: DateTime(2026, 11, 7, 18)),
      matchOf(id: 'b', date: DateTime(2026, 11, 8, 10)),
      matchOf(id: 'c', date: DateTime(2026, 11, 8, 12)),
    ]);

    expect(groups.map((g) => g.day), [DateTime(2026, 11, 7), DateTime(2026, 11, 8)]);
    expect(groups[1].matches.map((m) => m.id), ['b', 'c']);
  });

  test('con el orden de resultados (más reciente primero) cada día también sale una vez', () {
    final groups = groupMatchesByDay([
      matchOf(id: 'a', date: DateTime(2026, 11, 8, 18)),
      matchOf(id: 'b', date: DateTime(2026, 11, 8, 10)),
      matchOf(id: 'c', date: DateTime(2026, 11, 1, 10)),
    ]);

    expect(groups.map((g) => g.day), [DateTime(2026, 11, 8), DateTime(2026, 11, 1)]);
  });
}
