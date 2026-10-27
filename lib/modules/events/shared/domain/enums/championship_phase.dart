/// Una etapa del campeonato (`ChampionshipPhase` del backend). Se juegan en orden: una empieza cuando
/// termina la anterior.
enum ChampionshipPhase {
  league('LEAGUE'),
  groups('GROUPS'),
  swiss('SWISS'),
  knockout('KNOCKOUT'),
  doubleElimination('DOUBLE_ELIMINATION');

  const ChampionshipPhase(this.apiValue);

  final String apiValue;

  static ChampionshipPhase? fromApi(String? value) {
    for (final phase in values) {
      if (phase.apiValue == value) return phase;
    }
    return null;
  }

  /// Las etapas que ordenan a los equipos en una tabla de puntos.
  bool get hasPointsTable =>
      this == league || this == groups || this == swiss;

  /// Las etapas cuyas rondas se deciden en cruces que eliminan equipos.
  bool get isElimination => this == knockout || this == doubleElimination;

  String get translationKey => 'championship.phases.$apiValue';
}
