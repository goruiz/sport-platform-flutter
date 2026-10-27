/// Lo que hay que hacer a continuación para avanzar el campeonato (`ChampionshipAction` del backend).
/// La app solo lo muestra: quien genera las fases es el organizador desde el panel.
enum ChampionshipAction {
  noFormat('NO_FORMAT'),
  notEnoughTeams('NOT_ENOUGH_TEAMS'),
  generateCalendar('GENERATE_CALENDAR'),
  generateRound('GENERATE_ROUND'),
  waitingResults('WAITING_RESULTS'),
  needsTiebreak('NEEDS_TIEBREAK'),
  finished('FINISHED');

  const ChampionshipAction(this.apiValue);

  final String apiValue;

  static ChampionshipAction? fromApi(String? value) {
    for (final action in values) {
      if (action.apiValue == value) return action;
    }
    return null;
  }

  String get translationKey => 'championship.next_step.$apiValue';
}
