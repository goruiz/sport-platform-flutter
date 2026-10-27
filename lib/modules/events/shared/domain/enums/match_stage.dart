/// La parte del campeonato a la que pertenece un partido (`MatchStage` del backend). Un partido
/// creado a mano no tiene etapa y cuenta como un partido de liga.
enum MatchStage {
  league('LEAGUE'),
  group('GROUP'),
  swiss('SWISS'),
  knockout('KNOCKOUT'),

  /// El partido entre los dos semifinalistas que perdieron.
  thirdPlace('THIRD_PLACE'),

  /// Doble eliminación: los equipos que aún no perdieron.
  winners('WINNERS'),

  /// Doble eliminación: los equipos con una derrota.
  losers('LOSERS'),
  grandFinal('GRAND_FINAL');

  const MatchStage(this.apiValue);

  final String apiValue;

  static MatchStage? fromApi(String? value) {
    for (final stage in values) {
      if (stage.apiValue == value) return stage;
    }
    return null;
  }

  String get translationKey => 'championship.stages.$apiValue';
}
