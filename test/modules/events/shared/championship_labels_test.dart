import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/events/shared/data/models/championship_model.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/championship_phase.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/match_stage.dart';
import 'package:sport_platform/modules/events/shared/presentation/utils/championship_labels.dart';

TieModel _tie(MatchStage stage) => TieModel(tieNumber: 1, stage: stage);

ChampionshipRoundModel _round(
  ChampionshipPhase phase,
  int roundNumber,
  List<TieModel> ties,
) => ChampionshipRoundModel(phase: phase, roundNumber: roundNumber, ties: ties);

void main() {
  group('describeRound', () {
    test('una ronda de eliminatoria con un solo cruce es la final', () {
      final round = _round(ChampionshipPhase.knockout, 3, [
        _tie(MatchStage.knockout),
      ]);

      expect(describeRound(round).key, 'championship.round_final');
    });

    test(
      'la final con el partido por el tercer puesto sigue siendo la final',
      () {
        final round = _round(ChampionshipPhase.knockout, 3, [
          _tie(MatchStage.knockout),
          _tie(MatchStage.thirdPlace),
        ]);

        expect(describeRound(round).key, 'championship.round_final');
      },
    );

    test('2, 4 y 8 cruces son semifinales, cuartos y octavos', () {
      List<TieModel> ties(int count) =>
          List.generate(count, (_) => _tie(MatchStage.knockout));

      expect(
        describeRound(_round(ChampionshipPhase.knockout, 2, ties(2))).key,
        'championship.round_semifinals',
      );
      expect(
        describeRound(_round(ChampionshipPhase.knockout, 1, ties(4))).key,
        'championship.round_quarterfinals',
      );
      expect(
        describeRound(_round(ChampionshipPhase.knockout, 1, ties(8))).key,
        'championship.round_round_of_16',
      );
    });

    test('una ronda con otro número de cruces se numera', () {
      final round = _round(
        ChampionshipPhase.knockout,
        1,
        List.generate(3, (_) => _tie(MatchStage.knockout)),
      );

      final label = describeRound(round);

      expect(label.key, 'championship.round_number');
      expect(label.args, ['1']);
    });

    test('la doble eliminación se numera aunque tenga un solo cruce', () {
      final round = _round(ChampionshipPhase.doubleElimination, 4, [
        _tie(MatchStage.grandFinal),
      ]);

      final label = describeRound(round);

      expect(label.key, 'championship.round_number');
      expect(label.args, ['4']);
    });
  });

  group('describeTable', () {
    test('la tabla de un grupo lleva la letra del grupo', () {
      const table = ChampionshipTableModel(
        phase: ChampionshipPhase.groups,
        groupNumber: 2,
        entries: [],
      );

      final label = describeTable(table);

      expect(label.key, 'championship.table_group');
      expect(label.args, ['B']);
    });

    test('la de una liga o un suizo lleva el nombre de su etapa', () {
      const league = ChampionshipTableModel(
        phase: ChampionshipPhase.league,
        entries: [],
      );
      const swiss = ChampionshipTableModel(
        phase: ChampionshipPhase.swiss,
        entries: [],
      );

      expect(describeTable(league).key, 'championship.tables.LEAGUE');
      expect(describeTable(swiss).key, 'championship.tables.SWISS');
    });
  });

  group('groupLetter', () {
    test('numera los grupos con letras desde la A', () {
      expect(groupLetter(1), 'A');
      expect(groupLetter(2), 'B');
      expect(groupLetter(26), 'Z');
    });

    test('pasada la Z repite las letras con un número', () {
      expect(groupLetter(27), 'A1');
      expect(groupLetter(28), 'B1');
    });

    test('un número inválido se deja como viene', () {
      expect(groupLetter(0), '0');
    });
  });

  test('advancingRowsOf es cero si ninguna fila pasa a la eliminatoria', () {
    expect(advancingRowsOf(const ChampionshipModel(eventId: 'e')), 0);
    expect(
      advancingRowsOf(
        const ChampionshipModel(eventId: 'e', teamsAdvancingPerTable: 2),
      ),
      2,
    );
  });
}
