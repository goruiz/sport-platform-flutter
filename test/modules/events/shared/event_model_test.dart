import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/event_format_structure.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/event_status.dart';

Map<String, dynamic> _eventJson({
  Map<String, dynamic>? eventFormat,
  String status = 'ACTIVE',
}) => {
  'id': 'event-1',
  'name': 'Liga de barrio',
  'format': 'Todos contra todos',
  'status': status,
  'startDate': '2026-10-01',
  'endDate': '2026-12-01',
  'createdAt': '2026-09-01T10:00:00',
  'eventFormat': eventFormat,
};

void main() {
  group('EventModel.fromJson', () {
    test('lee la estructura del formato del evento', () {
      final event = EventModel.fromJson(
        _eventJson(
          eventFormat: {'name': 'Mundialito', 'structure': 'KNOCKOUT'},
        ),
      );

      expect(event.formatStructure, EventFormatStructure.knockout);
      expect(event.hasChampionship, isTrue);
    });

    test('lee los complejos donde se juega el evento', () {
      final json = {
        ..._eventJson(),
        'sportComplexIds': ['c1', 'c2'],
      };

      expect(EventModel.fromJson(json).sportComplexIds, ['c1', 'c2']);
    });

    test('un evento sin complejos asignados (o de un backend anterior) tiene la lista vacía', () {
      expect(EventModel.fromJson(_eventJson()).sportComplexIds, isEmpty);
      expect(EventModel.fromJson({..._eventJson(), 'sportComplexIds': null}).sportComplexIds, isEmpty);
    });

    test('un evento sin formato no tiene campeonato', () {
      final event = EventModel.fromJson(_eventJson());

      expect(event.formatStructure, isNull);
      expect(event.hasChampionship, isFalse);
    });

    test(
      'un formato anterior a las reglas (sin estructura) no tiene campeonato',
      () {
        final event = EventModel.fromJson(
          _eventJson(eventFormat: {'name': 'Antiguo', 'structure': null}),
        );

        expect(event.hasChampionship, isFalse);
      },
    );

    test('copyWith conserva la estructura', () {
      final event = EventModel.fromJson(
        _eventJson(eventFormat: {'structure': 'SWISS'}),
      );

      expect(
        event.copyWith(name: 'Otro nombre').formatStructure,
        EventFormatStructure.swiss,
      );
    });

    test('lee las reglas del formato y los límites de jugadores por equipo', () {
      final json = _eventJson(
        eventFormat: {
          'structure': 'ROUND_ROBIN',
          'pointsForWin': 3,
          'pointsForDraw': 1,
          'pointsForLoss': 0,
          'tiebreakers': ['GOAL_DIFFERENCE'],
        },
      )..addAll({'minPlayersPerTeam': 5, 'maxPlayersPerTeam': 12});

      final event = EventModel.fromJson(json);

      expect(event.formatRules?.pointsForWin, 3);
      expect(event.formatRules?.tiebreakers, hasLength(1));
      expect(event.minPlayersPerTeam, 5);
      expect(event.maxPlayersPerTeam, 12);
    });

    test('un evento que no fija límites de jugadores los deja en null', () {
      final event = EventModel.fromJson(_eventJson());

      expect(event.minPlayersPerTeam, isNull);
      expect(event.maxPlayersPerTeam, isNull);
      expect(event.formatRules, isNull);
    });

    test('copyWith conserva las reglas y los límites', () {
      final event = EventModel.fromJson(
        _eventJson(eventFormat: {'structure': 'KNOCKOUT', 'thirdPlaceMatch': true})
          ..addAll({'minPlayersPerTeam': 6}),
      );

      final copy = event.copyWith(name: 'Otro nombre');

      expect(copy.formatRules?.thirdPlaceMatch, isTrue);
      expect(copy.minPlayersPerTeam, 6);
    });
  });

  group('EventModel.statusType', () {
    test('reconoce los cuatro estados sin importar mayúsculas', () {
      expect(
        EventModel.fromJson(_eventJson(status: 'active')).statusType,
        EventStatus.active,
      );
      expect(
        EventModel.fromJson(_eventJson(status: 'FINISHED')).statusType,
        EventStatus.finished,
      );
    });

    test('un estado desconocido es null', () {
      expect(
        EventModel.fromJson(_eventJson(status: 'PAUSED')).statusType,
        isNull,
      );
    });
  });
}
