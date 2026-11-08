/// Lo que separa a dos equipos que terminan con los mismos puntos, como lo define el backend (`TiebreakerCriterion`).
/// Un formato los lista en orden de prioridad.
enum TiebreakerCriterion {
  goalDifference('GOAL_DIFFERENCE'),
  goalsFor('GOALS_FOR'),
  wins('WINS'),
  headToHead('HEAD_TO_HEAD'),

  /// La suma de los puntos de los rivales que enfrentó (Buchholz), el desempate habitual del sistema suizo.
  opponentsPoints('OPPONENTS_POINTS');

  const TiebreakerCriterion(this.apiValue);

  final String apiValue;

  /// Null si el backend trae uno que esta versión de la app no conoce.
  static TiebreakerCriterion? fromApi(String? value) {
    for (final criterion in values) {
      if (criterion.apiValue == value) return criterion;
    }
    return null;
  }

  String get translationKey => 'event_rules.tiebreaker.$apiValue';
}
