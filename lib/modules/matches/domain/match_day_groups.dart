import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';

/// Los partidos de un mismo día.
class MatchDayGroup {
  /// Medianoche de ese día (la hora no cuenta).
  final DateTime day;
  final List<MatchModel> matches;

  const MatchDayGroup({required this.day, required this.matches});
}

/// Agrupa los partidos por día respetando el orden en que llegan: los que son seguidos y de la misma fecha forman
/// un grupo. Como las listas ya vienen ordenadas por fecha, cada día sale una sola vez.
List<MatchDayGroup> groupMatchesByDay(List<MatchModel> matches) {
  final groups = <MatchDayGroup>[];
  for (final match in matches) {
    final day = DateTime(match.matchDate.year, match.matchDate.month, match.matchDate.day);
    if (groups.isNotEmpty && groups.last.day == day) {
      groups.last.matches.add(match);
    } else {
      groups.add(MatchDayGroup(day: day, matches: [match]));
    }
  }
  return groups;
}
