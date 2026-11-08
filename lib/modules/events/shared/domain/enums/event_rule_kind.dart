/// Cada regla que la pantalla «Reglas del torneo» puede mostrar. Su clave es el rótulo de la fila.
enum EventRuleKind {
  structure('event_rules.kinds.structure'),
  roundTrip('event_rules.kinds.round_trip'),
  points('event_rules.kinds.points'),
  tiebreakers('event_rules.kinds.tiebreakers'),
  swissRounds('event_rules.kinds.swiss_rounds'),
  groupCount('event_rules.kinds.group_count'),
  teamsAdvancingPerGroup('event_rules.kinds.teams_advancing_per_group'),
  playoffTeams('event_rules.kinds.playoff_teams'),
  knockoutRoundTrip('event_rules.kinds.knockout_round_trip'),
  thirdPlaceMatch('event_rules.kinds.third_place_match'),
  grandFinalReset('event_rules.kinds.grand_final_reset'),
  playersPerTeam('event_rules.kinds.players_per_team');

  const EventRuleKind(this.translationKey);

  final String translationKey;

  /// Sus valores van en orden de prioridad (el primero se aplica antes), así que se numeran.
  bool get isOrdered => this == EventRuleKind.tiebreakers;
}
