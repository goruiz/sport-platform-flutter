import 'package:sport_platform/core/utils/text_folding.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/sport_complexes/domain/complex_overview.dart';

/// Un evento con los complejos donde se juega, cada uno con sus canchas: así se organiza «Mi equipo».
class EventComplexes {
  final EventModel event;
  final List<ComplexOverview> overviews;

  const EventComplexes({required this.event, required this.overviews});
}

/// Agrupa los complejos de [overviews] por el evento de [events] que se juega en ellos, en el orden de [events]. Un complejo
/// donde se juegan varios eventos sale en cada uno; un evento sin complejos asignados (o cuyos complejos el jugador no ve) no
/// sale. Dentro de cada evento los complejos conservan el orden de [overviews].
List<EventComplexes> groupComplexesByEvent(Iterable<EventModel> events, List<ComplexOverview> overviews) {
  final groups = <EventComplexes>[];
  for (final event in events) {
    final complexIds = event.sportComplexIds.toSet();
    final ofEvent = overviews.where((overview) => complexIds.contains(overview.complex.id)).toList();
    if (ofEvent.isNotEmpty) groups.add(EventComplexes(event: event, overviews: ofEvent));
  }
  return groups;
}

/// Los eventos que coinciden con [query]: si coincide el nombre del evento sale con todos sus complejos; si no, solo con los
/// complejos que coinciden (por [filterComplexOverviews]) y sin ninguno no sale. Sin distinguir mayúsculas ni tildes.
List<EventComplexes> filterEventComplexes(List<EventComplexes> groups, String query) {
  final normalizedQuery = foldForComparison(query.trim());
  if (normalizedQuery.isEmpty) return groups;

  final filtered = <EventComplexes>[];
  for (final group in groups) {
    if (foldForComparison(group.event.name).contains(normalizedQuery)) {
      filtered.add(group);
      continue;
    }
    final matching = filterComplexOverviews(group.overviews, query);
    if (matching.isNotEmpty) filtered.add(EventComplexes(event: group.event, overviews: matching));
  }
  return filtered;
}
