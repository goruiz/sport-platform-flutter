import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/events/shared/data/models/championship_model.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/championship_action.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/championship_phase.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/event_format_structure.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/match_stage.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/phase_status.dart';

void main() {
  // La respuesta de GET /events/{id}/championship de un formato de grupos + eliminatoria.
  final groupsAndKnockout = <String, dynamic>{
    'eventId': 'event-1',
    'formatName': 'Mundialito',
    'structure': 'GROUPS_KNOCKOUT',
    'scheduleConfigured': true,
    'groupsDrawn': true,
    'teamsAdvancingPerTable': 2,
    'championTeamId': null,
    'nextStep': {
      'action': 'WAITING_RESULTS',
      'pendingMatches': 3,
      'registeredTeams': 4,
      'requiredTeams': 4,
    },
    'phases': [
      {'phase': 'GROUPS', 'status': 'FINISHED'},
      {'phase': 'KNOCKOUT', 'status': 'IN_PROGRESS'},
      {'phase': 'PHASE_FROM_THE_FUTURE', 'status': 'READY'},
    ],
    'teams': [
      {'teamId': 't1', 'teamName': 'Tigres', 'groupNumber': 1, 'seed': 1},
      {'teamId': 't2', 'teamName': 'Leones', 'groupNumber': 1, 'seed': 2},
    ],
    'tables': [
      {
        'phase': 'GROUPS',
        'groupNumber': 1,
        'entries': [
          {
            'position': 1,
            'teamId': 't1',
            'teamName': 'Tigres',
            'played': 3,
            'won': 2,
            'drawn': 1,
            'lost': 0,
            'goalsFor': 6,
            'goalsAgainst': 2,
            'goalDifference': 4,
            'points': 7,
          },
        ],
      },
    ],
    'rounds': [
      {'phase': 'GROUPS', 'roundNumber': 1, 'groupNumber': 1, 'ties': []},
      {
        'phase': 'KNOCKOUT',
        'roundNumber': 1,
        'ties': [
          {
            'tieNumber': 1,
            'stage': 'KNOCKOUT',
            'teamAId': 't1',
            'teamBId': null,
            'bye': true,
            'teamAGoals': 0,
            'teamBGoals': 0,
            'winnerTeamId': 't1',
            'needsTiebreak': false,
            'legs': [],
          },
          {
            'tieNumber': 2,
            'stage': 'THIRD_PLACE',
            'teamAId': 't2',
            'teamBId': 't3',
            'bye': false,
            'teamAGoals': 2,
            'teamBGoals': 2,
            'needsTiebreak': true,
            'legs': [
              {
                'matchId': 'm1',
                'homeTeamId': 't2',
                'awayTeamId': 't3',
                'homeScore': 2,
                'awayScore': 2,
                'legNumber': 1,
                'matchDate': '2026-10-30T18:00:00',
              },
            ],
          },
        ],
      },
    ],
  };

  group('ChampionshipModel.fromJson', () {
    test('lee la estructura, el siguiente paso y las tablas', () {
      final championship = ChampionshipModel.fromJson(groupsAndKnockout);

      expect(championship.hasChampionship, isTrue);
      expect(championship.structure, EventFormatStructure.groupsKnockout);
      expect(championship.formatName, 'Mundialito');
      expect(championship.teamsAdvancingPerTable, 2);
      expect(championship.nextStep?.action, ChampionshipAction.waitingResults);
      expect(championship.nextStep?.pendingMatches, 3);
      expect(championship.tables.single.groupNumber, 1);
      expect(championship.tables.single.entries.single.points, 7);
      expect(championship.hasChampion, isFalse);
    });

    test('descarta una etapa que esta versión de la app no conoce', () {
      final championship = ChampionshipModel.fromJson(groupsAndKnockout);

      expect(championship.phases.map((phase) => phase.phase), [
        ChampionshipPhase.groups,
        ChampionshipPhase.knockout,
      ]);
      expect(championship.phases.last.status, PhaseStatus.inProgress);
    });

    test('solo las rondas de eliminación forman la llave', () {
      final championship = ChampionshipModel.fromJson(groupsAndKnockout);

      expect(championship.rounds, hasLength(2));
      expect(
        championship.eliminationRounds.single.phase,
        ChampionshipPhase.knockout,
      );
    });

    test('lee un pase directo, un cruce empatado y sus partidos', () {
      final ties = ChampionshipModel.fromJson(
        groupsAndKnockout,
      ).eliminationRounds.single.ties;

      expect(ties.first.bye, isTrue);
      expect(ties.first.winnerTeamId, 't1');
      expect(ties.last.stage, MatchStage.thirdPlace);
      expect(ties.last.needsTiebreak, isTrue);
      expect(ties.last.hasResult, isTrue);
      expect(ties.last.legs.single.matchDate, DateTime(2026, 10, 30, 18));
    });

    test('un cruce sin partidos jugados no tiene resultado', () {
      final tie = TieModel.fromJson({
        'tieNumber': 1,
        'teamAId': 't1',
        'teamBId': 't2',
        'legs': [],
      });

      expect(tie.hasResult, isFalse);
    });

    test('un evento sin formato no tiene campeonato', () {
      final championship = ChampionshipModel.fromJson({
        'eventId': 'event-1',
        'structure': null,
      });

      expect(championship.hasChampionship, isFalse);
      expect(championship.tables, isEmpty);
      expect(championship.nextStep, isNull);
    });

    test('una estructura desconocida se trata como sin campeonato', () {
      final championship = ChampionshipModel.fromJson({
        'eventId': 'event-1',
        'structure': 'NEW_ONE',
      });

      expect(championship.hasChampionship, isFalse);
    });
  });

  group('ChampionshipModel.teamName', () {
    final championship = ChampionshipModel.fromJson(groupsAndKnockout);

    test('devuelve el nombre del equipo inscrito', () {
      expect(championship.teamName('t2'), 'Leones');
    });

    test('devuelve null para un hueco por definir o un equipo desconocido', () {
      expect(championship.teamName(null), isNull);
      expect(championship.teamName('nadie'), isNull);
    });
  });

  group('enums del campeonato', () {
    test('cada estructura se reconoce por el valor del backend', () {
      for (final structure in EventFormatStructure.values) {
        expect(EventFormatStructure.fromApi(structure.apiValue), structure);
      }
      expect(EventFormatStructure.fromApi(null), isNull);
    });

    test('un estado de etapa desconocido cuenta como pendiente', () {
      expect(PhaseStatus.fromApi('???'), PhaseStatus.pending);
    });

    test(
      'solo liga, grupos y suizo tienen tabla de puntos; solo las eliminatorias eliminan',
      () {
        expect(ChampionshipPhase.groups.hasPointsTable, isTrue);
        expect(ChampionshipPhase.knockout.hasPointsTable, isFalse);
        expect(ChampionshipPhase.doubleElimination.isElimination, isTrue);
        expect(ChampionshipPhase.swiss.isElimination, isFalse);
      },
    );
  });
}
