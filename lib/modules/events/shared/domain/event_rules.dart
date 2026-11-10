import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/event_status.dart';

/// Reglas de los eventos que usan varias pantallas. Funciones puras.

/// El orden de los estados en una lista: lo que pasa ahora, lo que viene y, al final, lo que ya terminó o se canceló.
const _statusesByRelevance = [
  EventStatus.active,
  EventStatus.upcoming,
  EventStatus.finished,
  EventStatus.cancelled,
];

/// Los eventos de [events] que cumplen la búsqueda [text] y el estado [status], en el mismo orden. Es lo que hace el
/// backend en `GET /events/search` para los eventos que la app ya leyó enteros (los de un equipo): cada palabra del texto
/// debe aparecer en el nombre o en la descripción, sin distinguir mayúsculas. Sin texto ni estado deja todos.
List<EventModel> filterEvents(Iterable<EventModel> events, {String text = '', EventStatus? status}) {
  final terms = text.toLowerCase().split(RegExp(r'\s+')).where((term) => term.isNotEmpty).toList();
  return events.where((event) {
    if (status != null && event.statusType != status) return false;
    final searchable = '${event.name} ${event.description ?? ''}'.toLowerCase();
    return terms.every(searchable.contains);
  }).toList();
}

/// Los ids de los complejos deportivos donde se juega alguno de [events], sin repetir. Un evento sin complejos asignados
/// no aporta ninguno.
Set<String> sportComplexIdsOfEvents(Iterable<EventModel> events) => {
      for (final event in events) ...event.sportComplexIds,
    };

/// Compara dos eventos en el orden en que el backend los lista: por estado (en curso, por iniciar, finalizado, cancelado y,
/// al final, un estado desconocido); entre los que están en curso o por iniciar, el que empieza antes primero, y entre
/// los demás, el que empezó más recientemente.
int compareEventsByRelevance(EventModel a, EventModel b) {
  final rankOfA = _relevanceRank(a);
  final rankOfB = _relevanceRank(b);
  if (rankOfA != rankOfB) return rankOfA.compareTo(rankOfB);
  final isStillToCome = rankOfA <= _statusesByRelevance.indexOf(EventStatus.upcoming);
  final byStart = isStillToCome ? a.startDate.compareTo(b.startDate) : b.startDate.compareTo(a.startDate);
  return byStart != 0 ? byStart : a.id.compareTo(b.id);
}

int _relevanceRank(EventModel event) {
  final status = event.statusType;
  return status == null ? _statusesByRelevance.length : _statusesByRelevance.indexOf(status);
}
