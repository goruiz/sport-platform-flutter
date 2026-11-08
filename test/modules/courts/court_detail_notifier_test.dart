import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/courts/data/datasource/court_availability_service.dart';
import 'package:sport_platform/modules/courts/data/models/court_availability_model.dart';
import 'package:sport_platform/modules/courts/presentation/providers/court_detail_notifier.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/matches/data/datasource/matches_service.dart';
import 'package:sport_platform/shared/enums/summary_status.dart';

import '../../support/builders.dart';

class _FakeAvailabilityService extends CourtAvailabilityService {
  final Future<CourtAvailabilityModel> Function(DateTime day) onRead;
  final List<DateTime> requestedDays = [];

  _FakeAvailabilityService(this.onRead);

  @override
  Future<CourtAvailabilityModel> getByDay(String courtId, DateTime day) {
    requestedDays.add(day);
    return onRead(day);
  }
}

class _FakeMatchesService extends MatchesService {
  final Future<List<MatchModel>> Function() onRead;
  DateTime? requestedFrom;

  _FakeMatchesService(this.onRead);

  @override
  Future<List<MatchModel>> getByCourt(String courtId, {DateTime? from}) {
    requestedFrom = from;
    return onRead();
  }
}

CourtAvailabilityModel _availabilityOf(DateTime day) => CourtAvailabilityModel(
      courtId: 'c1',
      date: day,
      opensAt: '08:00',
      closesAt: '22:00',
    );

final _now = DateTime(2026, 11, 7, 10, 30);

CourtDetailNotifier _notifier({
  Future<CourtAvailabilityModel> Function(DateTime day)? availability,
  Future<List<MatchModel>> Function()? matches,
  _FakeAvailabilityService? availabilityService,
  _FakeMatchesService? matchesService,
}) {
  return CourtDetailNotifier(
    availabilityService: availabilityService ?? _FakeAvailabilityService(availability ?? (day) async => _availabilityOf(day)),
    matchesService: matchesService ?? _FakeMatchesService(matches ?? () async => const []),
    courtId: 'c1',
    clock: () => _now,
  );
}

void main() {
  test('empieza en hoy y ofrece los días de la agenda', () {
    final notifier = _notifier();

    expect(notifier.selectedDay, DateTime(2026, 11, 7));
    expect(notifier.days.first, DateTime(2026, 11, 7));
    expect(notifier.days, hasLength(7));
  });

  test('al cargar lee los horarios de hoy y los partidos que vienen desde ahora', () async {
    final availabilityService = _FakeAvailabilityService((day) async => _availabilityOf(day));
    final matchesService = _FakeMatchesService(
      () async => [matchOf(id: 'm1', date: DateTime(2026, 11, 8)), matchOf(id: 'm2', date: DateTime(2026, 11, 9))],
    );
    final notifier = _notifier(availabilityService: availabilityService, matchesService: matchesService);

    await notifier.load();

    expect(availabilityService.requestedDays, [DateTime(2026, 11, 7)]);
    expect(matchesService.requestedFrom, _now);
    expect(notifier.availabilityStatus, SummaryStatus.ready);
    expect(notifier.availability?.opensAt, '08:00');
    expect(notifier.matchesStatus, SummaryStatus.ready);
    expect(notifier.upcomingMatches.map((match) => match.id), ['m1', 'm2']);
  });

  test('solo muestra los primeros partidos que vienen', () async {
    final notifier = _notifier(
      matches: () async => [
        for (var index = 0; index < 15; index++) matchOf(id: 'm$index', date: DateTime(2026, 11, 8 + index)),
      ],
    );

    await notifier.load();

    expect(notifier.upcomingMatches, hasLength(10));
    expect(notifier.upcomingMatches.first.id, 'm0');
  });

  test('elegir otro día lee sus horarios; elegir el mismo no repite la lectura', () async {
    final availabilityService = _FakeAvailabilityService((day) async => _availabilityOf(day));
    final notifier = _notifier(availabilityService: availabilityService);
    await notifier.load();

    await notifier.selectDay(DateTime(2026, 11, 9));
    await notifier.selectDay(DateTime(2026, 11, 9));

    expect(availabilityService.requestedDays, [DateTime(2026, 11, 7), DateTime(2026, 11, 9)]);
    expect(notifier.availability?.date, DateTime(2026, 11, 9));
  });

  test('la respuesta de un día que ya no es el elegido se descarta', () async {
    final slow = Completer<CourtAvailabilityModel>();
    final notifier = _notifier(
      availability: (day) => day == DateTime(2026, 11, 8) ? slow.future : Future.value(_availabilityOf(day)),
    );
    await notifier.load();

    final firstChange = notifier.selectDay(DateTime(2026, 11, 8));
    await notifier.selectDay(DateTime(2026, 11, 9));
    slow.complete(_availabilityOf(DateTime(2026, 11, 8)));
    await firstChange;

    expect(notifier.availability?.date, DateTime(2026, 11, 9));
  });

  test('si fallan los horarios, los partidos se siguen viendo', () async {
    final notifier = _notifier(
      availability: (_) => Future.error(Exception('sin red')),
      matches: () async => [matchOf(id: 'm1', date: DateTime(2026, 11, 8))],
    );

    await notifier.load();

    expect(notifier.availabilityStatus, SummaryStatus.failed);
    expect(notifier.availability, isNull);
    expect(notifier.matchesStatus, SummaryStatus.ready);
    expect(notifier.upcomingMatches, hasLength(1));
  });

  test('si fallan los partidos, los horarios se siguen viendo y se puede reintentar', () async {
    var shouldFail = true;
    final notifier = _notifier(
      matches: () => shouldFail
          ? Future.error(Exception('sin red'))
          : Future.value([matchOf(id: 'm1', date: DateTime(2026, 11, 8))]),
    );

    await notifier.load();
    expect(notifier.matchesStatus, SummaryStatus.failed);
    expect(notifier.availabilityStatus, SummaryStatus.ready);

    shouldFail = false;
    await notifier.retryMatches();

    expect(notifier.matchesStatus, SummaryStatus.ready);
    expect(notifier.upcomingMatches, hasLength(1));
  });
}
