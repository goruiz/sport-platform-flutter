/// La estructura de juego de un formato de evento, como la define el backend (`EventFormatStructure`).
/// Un evento sin formato, o con uno sin reglas, no tiene estructura: es una liga como antes.
enum EventFormatStructure {
  roundRobin('ROUND_ROBIN'),
  swiss('SWISS'),
  knockout('KNOCKOUT'),
  doubleElimination('DOUBLE_ELIMINATION'),
  groupsKnockout('GROUPS_KNOCKOUT'),
  leagueKnockout('LEAGUE_KNOCKOUT'),
  swissKnockout('SWISS_KNOCKOUT');

  const EventFormatStructure(this.apiValue);

  final String apiValue;

  /// Null si el backend no la envía o trae una que esta versión de la app no conoce.
  static EventFormatStructure? fromApi(String? value) {
    for (final structure in values) {
      if (structure.apiValue == value) return structure;
    }
    return null;
  }

  String get translationKey => 'championship.structures.$apiValue';
}
