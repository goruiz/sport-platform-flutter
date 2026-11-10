import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/court_model.dart';
import 'package:sport_platform/modules/sport_complexes/data/models/sport_complex_model.dart';
import 'package:sport_platform/modules/sport_complexes/domain/complex_overview.dart';

SportComplexModel _complex(String id, String name, {String? location, String? description}) =>
    SportComplexModel(id: id, name: name, location: location, description: description);

CourtModel _court(String id, String name, {String? complexId}) =>
    CourtModel(id: id, name: name, sportComplexId: complexId);

void main() {
  group('SportComplexModel.fromJson', () {
    test('lee la ubicación exacta cuando el organizador la marcó', () {
      final complex = SportComplexModel.fromJson({
        'id': 'c1',
        'name': 'Complejo Norte',
        'location': 'Av. Principal 123',
        'latitude': -0.18,
        'longitude': -78,
      });

      expect(complex.hasMapPosition, isTrue);
      expect(complex.latitude, -0.18);
      // Un entero de JSON también es una coordenada válida.
      expect(complex.longitude, -78.0);
    });

    test('un complejo anterior a la ubicación no tiene posición en el mapa', () {
      final complex = SportComplexModel.fromJson({
        'id': 'c1',
        'name': 'Complejo Viejo',
        'latitude': null,
        'longitude': null,
      });

      expect(complex.hasMapPosition, isFalse);
    });
  });

  group('buildComplexOverviews', () {
    test('junta cada cancha con su complejo y deja fuera las de complejos que no se ven', () {
      final overviews = buildComplexOverviews(
        [_complex('c1', 'Norte'), _complex('c2', 'Sur')],
        [
          _court('k1', 'Cancha 1', complexId: 'c1'),
          _court('k2', 'Cancha 2', complexId: 'c1'),
          _court('k3', 'Cancha A', complexId: 'c2'),
          _court('k4', 'De otra organización', complexId: 'c9'),
          _court('k5', 'Sin complejo'),
        ],
      );

      expect(overviews.map((overview) => overview.courts.length), [2, 1]);
      expect(overviews.expand((overview) => overview.courts).map((court) => court.id), isNot(contains('k4')));
      expect(overviews.expand((overview) => overview.courts).map((court) => court.id), isNot(contains('k5')));
    });

    test('ordena los complejos y sus canchas por nombre, sin distinguir mayúsculas', () {
      final overviews = buildComplexOverviews(
        [_complex('c1', 'zeta'), _complex('c2', 'Álamo'), _complex('c3', 'beta')],
        [
          _court('k1', 'cancha b', complexId: 'c3'),
          _court('k2', 'Cancha A', complexId: 'c3'),
        ],
      );

      expect(overviews.map((overview) => overview.complex.name), ['Álamo', 'beta', 'zeta']);
      expect(overviews[1].courts.map((court) => court.name), ['Cancha A', 'cancha b']);
    });

    test('un complejo sin canchas queda con la lista vacía', () {
      final overviews = buildComplexOverviews([_complex('c1', 'Norte')], const []);

      expect(overviews.single.courts, isEmpty);
    });
  });

  group('filterComplexOverviewsByIds', () {
    final overviews = buildComplexOverviews(
      [_complex('c1', 'Norte'), _complex('c2', 'Sur'), _complex('c3', 'Este')],
      [_court('k1', 'Cancha 1', complexId: 'c2')],
    );

    test('deja solo los complejos pedidos, en el mismo orden, con sus canchas', () {
      final result = filterComplexOverviewsByIds(overviews, {'c3', 'c2'});

      expect(result.map((overview) => overview.complex.name), ['Este', 'Sur']);
      expect(result.last.courts.single.name, 'Cancha 1');
    });

    test('sin ids (un equipo cuyos eventos no tienen complejos) no deja ninguno', () {
      expect(filterComplexOverviewsByIds(overviews, const {}), isEmpty);
    });

    test('un id que no es de ningún complejo visible se ignora', () {
      expect(filterComplexOverviewsByIds(overviews, {'otro'}), isEmpty);
    });
  });

  group('listCourtsWithoutComplex', () {
    test('deja solo las canchas sin complejo, por nombre', () {
      final result = listCourtsWithoutComplex([
        _court('k1', 'Zeta'),
        _court('k2', 'De un complejo', complexId: 'c1'),
        _court('k3', 'alfa'),
      ]);

      expect(result.map((court) => court.name), ['alfa', 'Zeta']);
    });
  });

  group('filterCourtsByQuery', () {
    final courts = [
      const CourtModel(id: 'k1', name: 'Cancha Bombonera', location: 'Av. Principal'),
      const CourtModel(id: 'k2', name: 'Cancha 2', description: 'Césped sintético'),
    ];

    List<String> idsFor(String query) => filterCourtsByQuery(courts, query).map((court) => court.id).toList();

    test('sin búsqueda deja todas', () {
      expect(idsFor('  '), ['k1', 'k2']);
    });

    test('busca en el nombre, la descripción y la ubicación sin distinguir mayúsculas ni tildes', () {
      expect(idsFor('BOMBONERA'), ['k1']);
      expect(idsFor('cesped'), ['k2']);
      expect(idsFor('principal'), ['k1']);
      expect(idsFor('nada'), isEmpty);
    });
  });

  group('filterComplexOverviews', () {
    final overviews = buildComplexOverviews(
      [
        _complex('c1', 'Complejo Norte', location: 'Av. Principal', description: 'Con vestuarios'),
        _complex('c2', 'Complejo Sur', location: 'Calle Sexta'),
      ],
      [_court('k1', 'Cancha Bombonera', complexId: 'c2')],
    );

    List<String> namesFor(String query) =>
        filterComplexOverviews(overviews, query).map((overview) => overview.complex.name).toList();

    test('sin búsqueda deja todos', () {
      expect(namesFor('  '), ['Complejo Norte', 'Complejo Sur']);
    });

    test('busca en el nombre, la dirección, la descripción y las canchas, sin mayúsculas', () {
      expect(namesFor('NORTE'), ['Complejo Norte']);
      expect(namesFor('sexta'), ['Complejo Sur']);
      expect(namesFor('vestuarios'), ['Complejo Norte']);
      expect(namesFor('bombonera'), ['Complejo Sur']);
    });

    test('sin coincidencias devuelve la lista vacía', () {
      expect(namesFor('inexistente'), isEmpty);
    });
  });
}
