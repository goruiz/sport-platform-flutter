import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/event_status.dart';
import 'package:sport_platform/modules/events/shared/domain/event_rules.dart';

import '../../support/builders.dart';

EventModel _event(
  String id, {
  String name = 'Evento',
  String? description,
  String status = 'ACTIVE',
  DateTime? startDate,
}) {
  final base = eventOf(
    id: id,
    name: name,
    status: status,
    startDate: startDate ?? DateTime(2026, 1, 1),
    endDate: DateTime(2026, 12, 1),
  );
  return description == null ? base : base.copyWith(description: description);
}

void main() {
  group('filterEvents', () {
    final liga = _event('liga', name: 'Liga de barrio', description: 'Fútbol sala los sábados');
    final copa = _event('copa', name: 'Copa Quito', status: 'FINISHED');
    final torneo = _event('torneo', name: 'Torneo relámpago', status: 'UPCOMING');
    final events = [liga, copa, torneo];

    test('sin texto ni estado deja todos, en el mismo orden', () {
      expect(filterEvents(events).map((event) => event.id), ['liga', 'copa', 'torneo']);
    });

    test('busca en el nombre y en la descripción sin distinguir mayúsculas', () {
      expect(filterEvents(events, text: 'QUITO').map((event) => event.id), ['copa']);
      expect(filterEvents(events, text: 'sábados').map((event) => event.id), ['liga']);
    });

    test('cada palabra debe aparecer, en cualquier orden', () {
      expect(filterEvents(events, text: 'barrio liga').map((event) => event.id), ['liga']);
      expect(filterEvents(events, text: 'liga quito'), isEmpty);
    });

    test('un texto en blanco no filtra', () {
      expect(filterEvents(events, text: '   '), hasLength(3));
    });

    test('filtra por estado', () {
      expect(filterEvents(events, status: EventStatus.finished).map((event) => event.id), ['copa']);
    });

    test('junta el texto y el estado', () {
      expect(filterEvents(events, text: 'copa', status: EventStatus.active), isEmpty);
      expect(filterEvents(events, text: 'copa', status: EventStatus.finished), hasLength(1));
    });

    test('un evento con un estado desconocido solo aparece sin filtrar por estado', () {
      final odd = _event('raro', status: 'OTRO');

      expect(filterEvents([odd]), hasLength(1));
      expect(filterEvents([odd], status: EventStatus.active), isEmpty);
    });
  });

  group('sportComplexIdsOfEvents', () {
    EventModel withComplexes(String id, List<String> complexIds) => eventOf(
          id: id,
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 12, 1),
          sportComplexIds: complexIds,
        );

    test('junta los complejos de todos los eventos, sin repetir', () {
      final events = [
        withComplexes('liga', ['norte', 'sur']),
        withComplexes('copa', ['sur', 'este']),
      ];

      expect(sportComplexIdsOfEvents(events), {'norte', 'sur', 'este'});
    });

    test('un evento sin complejos no aporta ninguno', () {
      expect(sportComplexIdsOfEvents([withComplexes('liga', const [])]), isEmpty);
      expect(sportComplexIdsOfEvents(const []), isEmpty);
    });
  });

  group('compareEventsByRelevance', () {
    List<String> sortedIds(List<EventModel> events) =>
        ([...events]..sort(compareEventsByRelevance)).map((event) => event.id).toList();

    test('primero lo que está en curso, luego lo que viene, luego lo que terminó y al final lo cancelado', () {
      final events = [
        _event('cancelado', status: 'CANCELLED'),
        _event('finalizado', status: 'FINISHED'),
        _event('por-iniciar', status: 'UPCOMING'),
        _event('en-curso', status: 'ACTIVE'),
      ];

      expect(sortedIds(events), ['en-curso', 'por-iniciar', 'finalizado', 'cancelado']);
    });

    test('un estado desconocido va al final', () {
      expect(sortedIds([_event('raro', status: 'OTRO'), _event('cancelado', status: 'CANCELLED')]), ['cancelado', 'raro']);
    });

    test('entre lo que está en curso o por iniciar, el que empieza antes primero', () {
      final events = [
        _event('tarde', startDate: DateTime(2026, 6, 1)),
        _event('temprano', startDate: DateTime(2026, 2, 1)),
      ];

      expect(sortedIds(events), ['temprano', 'tarde']);
    });

    test('entre lo que ya terminó, el que empezó más recientemente primero', () {
      final events = [
        _event('viejo', status: 'FINISHED', startDate: DateTime(2025, 1, 1)),
        _event('reciente', status: 'FINISHED', startDate: DateTime(2026, 5, 1)),
      ];

      expect(sortedIds(events), ['reciente', 'viejo']);
    });

    test('con todo igual, el id desempata para que el orden sea siempre el mismo', () {
      expect(sortedIds([_event('b'), _event('a')]), ['a', 'b']);
    });
  });
}
