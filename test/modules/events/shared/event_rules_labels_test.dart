import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_format_rules.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/event_format_structure.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/event_rule_kind.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/tiebreaker_criterion.dart';
import 'package:sport_platform/modules/events/shared/presentation/utils/event_rules_labels.dart';

const _league = EventFormatRules(
  structure: EventFormatStructure.roundRobin,
  roundTrip: true,
  pointsForWin: 3,
  pointsForDraw: 1,
  pointsForLoss: 0,
  tiebreakers: [TiebreakerCriterion.goalDifference, TiebreakerCriterion.goalsFor],
);

const _knockout = EventFormatRules(
  structure: EventFormatStructure.knockout,
  knockoutRoundTrip: false,
  thirdPlaceMatch: true,
);

List<EventRuleKind> _kindsOf(List<EventRuleLine> lines) => [for (final line in lines) line.kind];

EventRuleLine _lineOf(List<EventRuleLine> lines, EventRuleKind kind) => lines.firstWhere((line) => line.kind == kind);

List<String> _keysOf(EventRuleLine line) => [for (final value in line.values) value.key];

List<String> _argsOf(EventRuleLine line) => [for (final value in line.values) ...value.args];

void main() {
  group('describeEventRules', () {
    test('una liga cuenta su sistema, los cruces, los puntos y los desempates en orden de lectura', () {
      final lines = describeEventRules(_league);

      expect(_kindsOf(lines), [
        EventRuleKind.structure,
        EventRuleKind.roundTrip,
        EventRuleKind.points,
        EventRuleKind.tiebreakers,
      ]);
      expect(_keysOf(_lineOf(lines, EventRuleKind.structure)), ['championship.structures.ROUND_ROBIN']);
      expect(_keysOf(_lineOf(lines, EventRuleKind.roundTrip)), ['event_rules.values.round_trip_yes']);
    });

    test('los puntos van como victoria, empate y derrota', () {
      final points = _lineOf(describeEventRules(_league), EventRuleKind.points);

      expect(_keysOf(points), ['event_rules.values.points']);
      expect(_argsOf(points), ['3', '1', '0']);
    });

    test('los desempates salen uno por criterio y respetan su prioridad', () {
      final tiebreakers = _lineOf(describeEventRules(_league), EventRuleKind.tiebreakers);

      expect(_keysOf(tiebreakers), [
        'event_rules.tiebreaker.GOAL_DIFFERENCE',
        'event_rules.tiebreaker.GOALS_FOR',
      ]);
      expect(tiebreakers.kind.isOrdered, isTrue);
    });

    test('solo ida se dice «Solo ida» en la liga y «Partido único» en la eliminatoria', () {
      final league = describeEventRules(
        const EventFormatRules(structure: EventFormatStructure.roundRobin, roundTrip: false),
      );
      final knockout = describeEventRules(_knockout);

      expect(_keysOf(_lineOf(league, EventRuleKind.roundTrip)), ['event_rules.values.round_trip_no']);
      expect(_keysOf(_lineOf(knockout, EventRuleKind.knockoutRoundTrip)), ['event_rules.values.single_match']);
    });

    test('una eliminatoria no tiene puntos ni desempates, pero sí tercer puesto', () {
      final lines = describeEventRules(_knockout);

      expect(_kindsOf(lines), [
        EventRuleKind.structure,
        EventRuleKind.knockoutRoundTrip,
        EventRuleKind.thirdPlaceMatch,
      ]);
      expect(_keysOf(_lineOf(lines, EventRuleKind.thirdPlaceMatch)), ['event_rules.values.yes']);
    });

    test('grupos con eliminatoria cuenta cuántos grupos hay y cuántos equipos avanzan de cada uno', () {
      final lines = describeEventRules(
        const EventFormatRules(
          structure: EventFormatStructure.groupsKnockout,
          roundTrip: false,
          groupCount: 4,
          teamsAdvancingPerGroup: 2,
        ),
      );

      expect(_argsOf(_lineOf(lines, EventRuleKind.groupCount)), ['4']);
      expect(_argsOf(_lineOf(lines, EventRuleKind.teamsAdvancingPerGroup)), ['2']);
    });

    test('la revancha de la gran final y las rondas suizas salen cuando el formato las trae', () {
      final doubleElimination = describeEventRules(
        const EventFormatRules(structure: EventFormatStructure.doubleElimination, grandFinalReset: false),
      );
      final swiss = describeEventRules(
        const EventFormatRules(structure: EventFormatStructure.swiss, swissRounds: 5),
      );

      expect(_keysOf(_lineOf(doubleElimination, EventRuleKind.grandFinalReset)), ['event_rules.values.no']);
      expect(_argsOf(_lineOf(swiss, EventRuleKind.swissRounds)), ['5']);
    });

    test('un puntaje incompleto no se muestra a medias', () {
      final lines = describeEventRules(
        const EventFormatRules(structure: EventFormatStructure.roundRobin, pointsForWin: 3),
      );

      expect(_kindsOf(lines), [EventRuleKind.structure]);
    });

    test('los límites de jugadores por equipo: rango, solo mínimo, solo máximo o un número exacto', () {
      EventRuleLine players({int? min, int? max}) =>
          _lineOf(describeEventRules(null, minPlayersPerTeam: min, maxPlayersPerTeam: max), EventRuleKind.playersPerTeam);

      expect(_keysOf(players(min: 5, max: 12)), ['event_rules.values.players_between']);
      expect(_argsOf(players(min: 5, max: 12)), ['5', '12']);
      expect(_keysOf(players(min: 5)), ['event_rules.values.players_min']);
      expect(_keysOf(players(max: 12)), ['event_rules.values.players_max']);
      expect(_keysOf(players(min: 7, max: 7)), ['event_rules.values.number']);
      expect(_argsOf(players(min: 7, max: 7)), ['7']);
    });

    test('los jugadores por equipo van al final, después de las reglas del formato', () {
      final lines = describeEventRules(_league, minPlayersPerTeam: 5, maxPlayersPerTeam: 12);

      expect(_kindsOf(lines).last, EventRuleKind.playersPerTeam);
    });

    test('sin reglas ni límites no hay nada que mostrar', () {
      expect(describeEventRules(null), isEmpty);
    });
  });

  group('textos', () {
    // Una clave sin traducir se vería cruda en pantalla: toda la que arma esta lógica debe existir en español.
    final spanish = jsonDecode(File('assets/translations/es.json').readAsStringSync()) as Map<String, dynamic>;

    bool exists(String key) {
      Object? node = spanish;
      for (final part in key.split('.')) {
        if (node is! Map<String, dynamic> || !node.containsKey(part)) return false;
        node = node[part];
      }
      return node is String;
    }

    test('cada regla y cada desempate tienen su texto', () {
      for (final kind in EventRuleKind.values) {
        expect(exists(kind.translationKey), isTrue, reason: kind.translationKey);
      }
      for (final criterion in TiebreakerCriterion.values) {
        expect(exists(criterion.translationKey), isTrue, reason: criterion.translationKey);
      }
    });

    test('todas las claves de valores que se arman existen', () {
      const every = EventFormatRules(
        structure: EventFormatStructure.groupsKnockout,
        roundTrip: true,
        pointsForWin: 3,
        pointsForDraw: 1,
        pointsForLoss: 0,
        tiebreakers: TiebreakerCriterion.values,
        swissRounds: 3,
        groupCount: 4,
        teamsAdvancingPerGroup: 2,
        playoffTeams: 8,
        knockoutRoundTrip: false,
        thirdPlaceMatch: true,
        grandFinalReset: false,
      );
      final lines = [
        ...describeEventRules(every, minPlayersPerTeam: 5, maxPlayersPerTeam: 12),
        ...describeEventRules(null, minPlayersPerTeam: 5),
        ...describeEventRules(null, maxPlayersPerTeam: 12),
        ...describeEventRules(const EventFormatRules(structure: EventFormatStructure.knockout, knockoutRoundTrip: true)),
        ...describeEventRules(const EventFormatRules(structure: EventFormatStructure.roundRobin, roundTrip: false)),
      ];

      for (final line in lines) {
        for (final value in line.values) {
          expect(exists(value.key), isTrue, reason: value.key);
        }
      }
    });
  });

  group('EventFormatRules.fromJson', () {
    test('lee las reglas que el backend manda y deja en null las que la estructura no usa', () {
      final rules = EventFormatRules.fromJson({
        'structure': 'GROUPS_KNOCKOUT',
        'roundTrip': false,
        'pointsForWin': 3,
        'pointsForDraw': 1,
        'pointsForLoss': 0,
        'tiebreakers': ['GOAL_DIFFERENCE', 'HEAD_TO_HEAD'],
        'swissRounds': null,
        'groupCount': 4,
        'teamsAdvancingPerGroup': 2,
        'knockoutRoundTrip': true,
        'thirdPlaceMatch': true,
      })!;

      expect(rules.structure, EventFormatStructure.groupsKnockout);
      expect(rules.hasPoints, isTrue);
      expect(rules.tiebreakers, [TiebreakerCriterion.goalDifference, TiebreakerCriterion.headToHead]);
      expect(rules.groupCount, 4);
      expect(rules.swissRounds, isNull);
      expect(rules.playoffTeams, isNull);
      expect(rules.grandFinalReset, isNull);
    });

    test('un desempate que la app no conoce se omite sin romper el resto', () {
      final rules = EventFormatRules.fromJson({
        'structure': 'ROUND_ROBIN',
        'tiebreakers': ['GOALS_FOR', 'DISCIPLINE_POINTS', 'WINS'],
      })!;

      expect(rules.tiebreakers, [TiebreakerCriterion.goalsFor, TiebreakerCriterion.wins]);
    });

    test('un formato sin estructura (anterior a las reglas) o desconocida no tiene reglas', () {
      expect(EventFormatRules.fromJson({'name': 'Antiguo', 'structure': null}), isNull);
      expect(EventFormatRules.fromJson({'structure': 'FUTURE_STRUCTURE'}), isNull);
      expect(EventFormatRules.fromJson(null), isNull);
    });
  });
}
