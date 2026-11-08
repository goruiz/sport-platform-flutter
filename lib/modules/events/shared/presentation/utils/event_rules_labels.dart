import 'package:sport_platform/modules/events/shared/data/models/event_format_rules.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/event_rule_kind.dart';
import 'package:sport_platform/modules/events/shared/presentation/utils/championship_labels.dart';

/// Una regla del torneo lista para mostrar: de qué regla es y su valor, uno o varios textos traducibles
/// (los desempates son uno por criterio, en orden de prioridad).
typedef EventRuleLine = ({EventRuleKind kind, List<TextKey> values});

const _numberKey = 'event_rules.values.number';
const _yesKey = 'event_rules.values.yes';
const _noKey = 'event_rules.values.no';

/// Las reglas que tiene el evento, en el orden en que se leen. Solo salen las que su formato usa (el backend manda
/// `null` en las demás) y los límites de jugadores por equipo si el evento los fija. Vacía si no hay nada que decir.
List<EventRuleLine> describeEventRules(
  EventFormatRules? rules, {
  int? minPlayersPerTeam,
  int? maxPlayersPerTeam,
}) {
  return [
    if (rules != null) ..._describeFormatRules(rules),
    ?_describePlayersPerTeam(minPlayersPerTeam, maxPlayersPerTeam),
  ];
}

List<EventRuleLine> _describeFormatRules(EventFormatRules rules) {
  return [
    (kind: EventRuleKind.structure, values: [_text(rules.structure.translationKey)]),
    ?_legsLine(EventRuleKind.roundTrip, rules.roundTrip, singleLegKey: 'event_rules.values.round_trip_no'),
    ?_pointsLine(rules),
    ?_tiebreakersLine(rules),
    ?_numberLine(EventRuleKind.swissRounds, rules.swissRounds),
    ?_numberLine(EventRuleKind.groupCount, rules.groupCount),
    ?_numberLine(EventRuleKind.teamsAdvancingPerGroup, rules.teamsAdvancingPerGroup),
    ?_numberLine(EventRuleKind.playoffTeams, rules.playoffTeams),
    ?_legsLine(EventRuleKind.knockoutRoundTrip, rules.knockoutRoundTrip, singleLegKey: 'event_rules.values.single_match'),
    ?_yesNoLine(EventRuleKind.thirdPlaceMatch, rules.thirdPlaceMatch),
    ?_yesNoLine(EventRuleKind.grandFinalReset, rules.grandFinalReset),
  ];
}

EventRuleLine? _pointsLine(EventFormatRules rules) {
  if (!rules.hasPoints) return null;
  return (
    kind: EventRuleKind.points,
    values: [
      _text('event_rules.values.points', ['${rules.pointsForWin}', '${rules.pointsForDraw}', '${rules.pointsForLoss}']),
    ],
  );
}

EventRuleLine? _tiebreakersLine(EventFormatRules rules) {
  if (rules.tiebreakers.isEmpty) return null;
  return (
    kind: EventRuleKind.tiebreakers,
    values: [for (final criterion in rules.tiebreakers) _text(criterion.translationKey)],
  );
}

/// «Ida y vuelta» o, si no, el texto de [singleLegKey] (en la liga «Solo ida»; en la eliminatoria «Partido único»).
EventRuleLine? _legsLine(EventRuleKind kind, bool? isRoundTrip, {required String singleLegKey}) {
  if (isRoundTrip == null) return null;
  return (
    kind: kind,
    values: [_text(isRoundTrip ? 'event_rules.values.round_trip_yes' : singleLegKey)],
  );
}

EventRuleLine? _yesNoLine(EventRuleKind kind, bool? value) {
  if (value == null) return null;
  return (kind: kind, values: [_text(value ? _yesKey : _noKey)]);
}

EventRuleLine? _numberLine(EventRuleKind kind, int? value) {
  if (value == null) return null;
  return (kind: kind, values: [_text(_numberKey, ['$value'])]);
}

/// «De 5 a 12», «Mínimo 5» o «Máximo 12»; si ambos coinciden, ese número. Null si el evento no fija ninguno.
EventRuleLine? _describePlayersPerTeam(int? min, int? max) {
  final TextKey? value;
  if (min != null && max != null) {
    value = min == max ? _text(_numberKey, ['$min']) : _text('event_rules.values.players_between', ['$min', '$max']);
  } else if (min != null) {
    value = _text('event_rules.values.players_min', ['$min']);
  } else if (max != null) {
    value = _text('event_rules.values.players_max', ['$max']);
  } else {
    value = null;
  }
  if (value == null) return null;
  return (kind: EventRuleKind.playersPerTeam, values: [value]);
}

TextKey _text(String key, [List<String> args = const []]) => (key: key, args: args);
