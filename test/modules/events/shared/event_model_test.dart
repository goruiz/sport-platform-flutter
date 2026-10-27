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
