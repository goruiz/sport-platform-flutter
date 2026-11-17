import 'package:sport_platform/core/constants/locale_keys.g.dart';
/// Cada regla que la pantalla «Reglas del torneo» puede mostrar. Su clave es el rótulo de la fila.
enum EventRuleKind {
  structure(LocaleKeys.event_rules_kinds_structure),
  roundTrip(LocaleKeys.event_rules_kinds_round_trip),
  points(LocaleKeys.event_rules_kinds_points),
  tiebreakers(LocaleKeys.event_rules_kinds_tiebreakers),
  swissRounds(LocaleKeys.event_rules_kinds_swiss_rounds),
  groupCount(LocaleKeys.event_rules_kinds_group_count),
  teamsAdvancingPerGroup(LocaleKeys.event_rules_kinds_teams_advancing_per_group),
  playoffTeams(LocaleKeys.event_rules_kinds_playoff_teams),
  knockoutRoundTrip(LocaleKeys.event_rules_kinds_knockout_round_trip),
  thirdPlaceMatch(LocaleKeys.event_rules_kinds_third_place_match),
  grandFinalReset(LocaleKeys.event_rules_kinds_grand_final_reset),
  playersPerTeam(LocaleKeys.event_rules_kinds_players_per_team);

  const EventRuleKind(this.translationKey);

  final String translationKey;

  /// Sus valores van en orden de prioridad (el primero se aplica antes), así que se numeran.
  bool get isOrdered => this == EventRuleKind.tiebreakers;
}
