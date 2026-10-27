import 'package:sport_platform/modules/events/shared/data/models/championship_model.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/championship_phase.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/match_stage.dart';

/// Un texto traducible: la clave y los valores de sus `{}`. La UI lo resuelve con `tr(args: …)`, así
/// la lógica sigue sin depender del idioma ni de Flutter.
typedef TextKey = ({String key, List<String> args});

/// Cuántos cruces tiene una ronda de eliminación directa → su nombre de toda la vida.
const _knockoutRoundKeys = <int, String>{
  1: 'championship.round_final',
  2: 'championship.round_semifinals',
  4: 'championship.round_quarterfinals',
  8: 'championship.round_round_of_16',
};

/// El nombre de una ronda de la llave: «Final», «Semifinales», «Cuartos de final»… por el número de
/// cruces de la eliminatoria; el resto (y la doble eliminación) se numera.
TextKey describeRound(ChampionshipRoundModel round) {
  final knockoutTies =
      round.ties.where((tie) => tie.stage == MatchStage.knockout).length;
  final namedKey = round.phase == ChampionshipPhase.knockout
      ? _knockoutRoundKeys[knockoutTies]
      : null;
  if (namedKey != null) return (key: namedKey, args: const []);
  return (key: 'championship.round_number', args: ['${round.roundNumber}']);
}

/// El título de la tabla de una etapa: la de un grupo lleva su letra («Grupo A»).
TextKey describeTable(ChampionshipTableModel table) {
  final group = table.groupNumber;
  if (table.phase == ChampionshipPhase.groups && group != null) {
    return (key: 'championship.table_group', args: [groupLetter(group)]);
  }
  return (key: 'championship.tables.${table.phase.apiValue}', args: const []);
}

/// Los grupos se numeran desde 1 en el backend y se muestran como letras: 1 → A, 2 → B…
String groupLetter(int groupNumber) {
  const firstLetter = 0x41; // 'A'
  const lettersInAlphabet = 26;
  if (groupNumber < 1) return '$groupNumber';
  final offset = (groupNumber - 1) % lettersInAlphabet;
  final cycles = (groupNumber - 1) ~/ lettersInAlphabet;
  final letter = String.fromCharCode(firstLetter + offset);
  return cycles == 0 ? letter : '$letter$cycles';
}

/// Cuántas filas de una tabla pasan a la eliminatoria (las primeras); 0 si ninguna.
int advancingRowsOf(ChampionshipModel championship) =>
    championship.teamsAdvancingPerTable ?? 0;
