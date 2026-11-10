import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/court_model.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/sport_complexes/data/models/sport_complex_model.dart';
import 'package:sport_platform/modules/sport_complexes/domain/complex_overview.dart';
import 'package:sport_platform/modules/sport_complexes/domain/event_complexes.dart';

import '../../support/builders.dart';

EventModel _event(String id, String name, List<String> complexIds) => eventOf(
      id: id,
      name: name,
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 12, 1),
      sportComplexIds: complexIds,
    );

void main() {
  final overviews = buildComplexOverviews(
    const [
      SportComplexModel(id: 'norte', name: 'Complejo Norte', location: 'Av. Principal'),
      SportComplexModel(id: 'sur', name: 'Complejo Sur'),
      SportComplexModel(id: 'este', name: 'Complejo Este'),
    ],
    const [
      CourtModel(id: 'k1', name: 'Cancha Bombonera', sportComplexId: 'sur'),
    ],
  );

  List<String> complexNames(EventComplexes group) => group.overviews.map((overview) => overview.complex.name).toList();

  group('groupComplexesByEvent', () {
    test('organiza los complejos por evento, en el orden de los eventos', () {
      final groups = groupComplexesByEvent(
        [_event('copa', 'Copa', ['sur']), _event('liga', 'Liga', ['norte', 'este'])],
        overviews,
      );

      expect(groups.map((group) => group.event.id), ['copa', 'liga']);
      expect(complexNames(groups[0]), ['Complejo Sur']);
      // Dentro de un evento, los complejos conservan el orden por nombre.
      expect(complexNames(groups[1]), ['Complejo Este', 'Complejo Norte']);
    });

    test('un complejo donde se juegan varios eventos sale en cada uno, con sus canchas', () {
      final groups = groupComplexesByEvent(
        [_event('liga', 'Liga', ['sur']), _event('copa', 'Copa', ['sur'])],
        overviews,
      );

      expect(groups, hasLength(2));
      expect(groups[0].overviews.single.courts.single.name, 'Cancha Bombonera');
      expect(groups[1].overviews.single.courts.single.name, 'Cancha Bombonera');
    });

    test('un evento sin complejos asignados no sale', () {
      final groups = groupComplexesByEvent(
        [_event('liga', 'Liga', const []), _event('copa', 'Copa', ['norte'])],
        overviews,
      );

      expect(groups.map((group) => group.event.id), ['copa']);
    });

    test('un complejo que el jugador no ve (no está en la lista) se ignora, y el evento sin ninguno no sale', () {
      final groups = groupComplexesByEvent(
        [_event('liga', 'Liga', ['de-otra-organizacion']), _event('copa', 'Copa', ['norte', 'de-otra-organizacion'])],
        overviews,
      );

      expect(groups.map((group) => group.event.id), ['copa']);
      expect(complexNames(groups.single), ['Complejo Norte']);
    });

    test('sin eventos no hay nada', () {
      expect(groupComplexesByEvent(const [], overviews), isEmpty);
    });
  });

  group('filterEventComplexes', () {
    final groups = groupComplexesByEvent(
      [_event('liga', 'Liga de Barrio', ['norte', 'sur']), _event('copa', 'Copa Quito', ['este'])],
      overviews,
    );

    List<String> eventIdsFor(String query) => filterEventComplexes(groups, query).map((group) => group.event.id).toList();

    test('sin búsqueda deja todo', () {
      expect(filterEventComplexes(groups, '  '), same(groups));
    });

    test('si coincide el nombre del evento sale con todos sus complejos, sin distinguir mayúsculas ni tildes', () {
      final result = filterEventComplexes(groups, 'BARRIÓ');

      expect(result.map((group) => group.event.id), ['liga']);
      expect(complexNames(result.single), ['Complejo Norte', 'Complejo Sur']);
    });

    test('si no, deja solo los complejos que coinciden (por nombre, dirección o cancha) y los eventos que se quedan con alguno', () {
      expect(eventIdsFor('principal'), ['liga']);
      expect(complexNames(filterEventComplexes(groups, 'principal').single), ['Complejo Norte']);
      expect(complexNames(filterEventComplexes(groups, 'bombonera').single), ['Complejo Sur']);
      expect(eventIdsFor('este'), ['copa']);
    });

    test('sin coincidencias no deja ningún evento', () {
      expect(eventIdsFor('inexistente'), isEmpty);
    });
  });
}
