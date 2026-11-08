import 'package:sport_platform/modules/courts/data/models/court_availability_model.dart';

/// Si un tramo del día de una cancha está libre o lo ocupa un partido.
enum DayTimelineKind { free, busy }

/// Una línea del día de una cancha: un tramo libre o uno ocupado por un partido.
class DayTimelineEntry {
  final DayTimelineKind kind;
  final DateTime startsAt;
  final DateTime endsAt;

  /// «Local – Visitante» del partido que ocupa el tramo; null en un tramo libre o si no se ven los equipos.
  final String? matchTitle;

  const DayTimelineEntry({
    required this.kind,
    required this.startsAt,
    required this.endsAt,
    this.matchTitle,
  });

  Duration get duration => endsAt.difference(startsAt);
}

/// Los días que se pueden consultar: hoy y los [count] - 1 siguientes, cada uno a la medianoche.
List<DateTime> buildAgendaDays(DateTime today, {required int count}) => [
      for (var offset = 0; offset < count; offset++)
        DateTime(today.year, today.month, today.day + offset),
    ];

/// El día de la cancha de la primera hora a la última: los tramos libres y los ocupados juntos, en orden.
List<DayTimelineEntry> buildDayTimeline(CourtAvailabilityModel availability) {
  final entries = [
    for (final slot in availability.freeSlots)
      DayTimelineEntry(kind: DayTimelineKind.free, startsAt: slot.startsAt, endsAt: slot.endsAt),
    for (final slot in availability.busySlots)
      DayTimelineEntry(
        kind: DayTimelineKind.busy,
        startsAt: slot.startsAt,
        endsAt: slot.endsAt,
        matchTitle: describeBusyMatch(slot),
      ),
  ];
  entries.sort((a, b) {
    final byStart = a.startsAt.compareTo(b.startsAt);
    return byStart != 0 ? byStart : a.endsAt.compareTo(b.endsAt);
  });
  return entries;
}

/// «Local – Visitante»; null si el jugador no ve ninguno de los dos equipos.
String? describeBusyMatch(CourtBusySlot slot) {
  final home = slot.homeTeamName;
  final away = slot.awayTeamName;
  if (home == null && away == null) return null;
  return '${home ?? '—'} – ${away ?? '—'}';
}

/// La duración de un tramo en horas y minutos, para decir cuánto dura un hueco libre: «1 h 30 min», «45 min», «2 h».
/// Las unidades son las mismas en todos los idiomas.
String formatSlotDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  return [
    if (hours > 0) '$hours h',
    if (minutes > 0 || hours == 0) '$minutes min',
  ].join(' ');
}
