import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/courts/data/models/court_availability_model.dart';
import 'package:sport_platform/modules/courts/domain/court_agenda.dart';

CourtTimeSlot _free(int fromHour, int toHour) => CourtTimeSlot(
      startsAt: DateTime(2026, 11, 10, fromHour),
      endsAt: DateTime(2026, 11, 10, toHour),
    );

CourtBusySlot _busy(int fromHour, int toHour, {String? home, String? away}) => CourtBusySlot(
      startsAt: DateTime(2026, 11, 10, fromHour),
      endsAt: DateTime(2026, 11, 10, toHour),
      matchId: 'm-$fromHour',
      homeTeamName: home,
      awayTeamName: away,
    );

CourtAvailabilityModel _availability({
  List<CourtBusySlot> busy = const [],
  List<CourtTimeSlot> free = const [],
}) => CourtAvailabilityModel(
      courtId: 'c1',
      date: DateTime(2026, 11, 10),
      opensAt: '08:00',
      closesAt: '22:00',
      busySlots: busy,
      freeSlots: free,
    );

void main() {
  group('buildAgendaDays', () {
    test('empieza hoy a la medianoche y suma un día por cada lugar', () {
      final days = buildAgendaDays(DateTime(2026, 11, 7, 18, 45), count: 3);

      expect(days, [DateTime(2026, 11, 7), DateTime(2026, 11, 8), DateTime(2026, 11, 9)]);
    });

    test('cruza el fin de mes sin saltarse ni repetir días', () {
      final days = buildAgendaDays(DateTime(2026, 11, 29), count: 3);

      expect(days.last, DateTime(2026, 12, 1));
    });
  });

  group('buildDayTimeline', () {
    test('junta los tramos libres y los ocupados en orden de hora', () {
      final timeline = buildDayTimeline(
        _availability(
          free: [_free(8, 16), _free(18, 22)],
          busy: [_busy(16, 18, home: 'Tigres', away: 'Halcones')],
        ),
      );

      expect(timeline.map((entry) => entry.kind), [
        DayTimelineKind.free,
        DayTimelineKind.busy,
        DayTimelineKind.free,
      ]);
      expect(timeline[1].matchTitle, 'Tigres – Halcones');
    });

    test('un día sin partidos es un solo tramo libre', () {
      final timeline = buildDayTimeline(_availability(free: [_free(8, 22)]));

      expect(timeline, hasLength(1));
      expect(timeline.single.duration, const Duration(hours: 14));
    });

    test('un día sin nada devuelve la lista vacía', () {
      expect(buildDayTimeline(_availability()), isEmpty);
    });
  });

  group('describeBusyMatch', () {
    test('rotula con ambos equipos', () {
      expect(describeBusyMatch(_busy(9, 10, home: 'A', away: 'B')), 'A – B');
    });

    test('un equipo que no se ve se marca con un guion', () {
      expect(describeBusyMatch(_busy(9, 10, home: 'A')), 'A – —');
    });

    test('sin ningún nombre no hay título', () {
      expect(describeBusyMatch(_busy(9, 10)), isNull);
    });
  });

  group('formatSlotDuration', () {
    test('horas y minutos', () => expect(formatSlotDuration(const Duration(minutes: 90)), '1 h 30 min'));
    test('solo minutos', () => expect(formatSlotDuration(const Duration(minutes: 45)), '45 min'));
    test('horas exactas no llevan minutos', () => expect(formatSlotDuration(const Duration(hours: 2)), '2 h'));
  });

  group('CourtAvailabilityModel.fromJson', () {
    test('lee la apertura sin segundos y los tramos', () {
      final model = CourtAvailabilityModel.fromJson({
        'courtId': 'c1',
        'date': '2026-11-10',
        'opensAt': '08:00:00',
        'closesAt': '22:00:00',
        'busySlots': [
          {
            'matchId': 'm1',
            'startsAt': '2026-11-10T16:00:00',
            'endsAt': '2026-11-10T17:45:00',
            'homeTeamName': 'Tigres',
            'awayTeamName': 'Halcones',
            'status': 'SCHEDULED',
          },
        ],
        'freeSlots': [
          {'startsAt': '2026-11-10T08:00:00', 'endsAt': '2026-11-10T16:00:00'},
        ],
      });

      expect(model.opensAt, '08:00');
      expect(model.closesAt, '22:00');
      expect(model.busySlots.single.homeTeamName, 'Tigres');
      expect(model.freeSlots.single.duration, const Duration(hours: 8));
    });

    test('sin tramos las listas quedan vacías', () {
      final model = CourtAvailabilityModel.fromJson({
        'courtId': 'c1',
        'date': '2026-11-10',
        'opensAt': '08:00',
        'closesAt': '22:00',
      });

      expect(model.busySlots, isEmpty);
      expect(model.freeSlots, isEmpty);
    });
  });
}
