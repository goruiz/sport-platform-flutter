import 'package:sport_platform/core/network/json_reader.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/championship_action.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/championship_phase.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/event_format_structure.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/match_stage.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/phase_status.dart';

/// Dónde está el campeonato de un evento: sus etapas, las tablas de puntos, las rondas con sus
/// cruces y qué sigue. Todo lo calcula el backend a partir del formato del evento y sus partidos;
/// la app solo lo muestra.
class ChampionshipModel {
  final String eventId;
  final String? formatName;

  /// Null si el evento no tiene formato (o su formato no tiene reglas): no hay campeonato que mostrar.
  final EventFormatStructure? structure;
  final bool scheduleConfigured;
  final bool groupsDrawn;

  /// Cuántos equipos de cada tabla (grupo, liga o suizo) pasan a la eliminatoria; null si no hay.
  final int? teamsAdvancingPerTable;
  final String? championTeamId;
  final NextStepModel? nextStep;
  final List<PhaseModel> phases;
  final List<ChampionshipTeamModel> teams;
  final List<ChampionshipTableModel> tables;
  final List<ChampionshipRoundModel> rounds;

  const ChampionshipModel({
    required this.eventId,
    this.formatName,
    this.structure,
    this.scheduleConfigured = false,
    this.groupsDrawn = false,
    this.teamsAdvancingPerTable,
    this.championTeamId,
    this.nextStep,
    this.phases = const [],
    this.teams = const [],
    this.tables = const [],
    this.rounds = const [],
  });

  bool get hasChampionship => structure != null;

  bool get hasChampion => championTeamId != null;

  /// Las rondas de las etapas que eliminan equipos, que son las que se dibujan como llave.
  List<ChampionshipRoundModel> get eliminationRounds =>
      rounds.where((round) => round.phase.isElimination).toList();

  /// El nombre de un equipo, o null si el campeonato no lo conoce (p. ej. un hueco "por definir").
  String? teamName(String? teamId) {
    if (teamId == null) return null;
    for (final team in teams) {
      if (team.teamId == teamId) return team.teamName;
    }
    return null;
  }

  factory ChampionshipModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, resource: 'campeonato');
    return ChampionshipModel(
      eventId: reader.requiredString('eventId'),
      formatName: reader.optionalString('formatName'),
      structure: EventFormatStructure.fromApi(reader.optionalString('structure')),
      scheduleConfigured: reader.flag('scheduleConfigured'),
      groupsDrawn: reader.flag('groupsDrawn'),
      teamsAdvancingPerTable: reader.optionalInt('teamsAdvancingPerTable'),
      championTeamId: reader.optionalString('championTeamId'),
      nextStep: json['nextStep'] is Map<String, dynamic>
          ? NextStepModel.fromJson(json['nextStep'] as Map<String, dynamic>)
          : null,
      phases: reader.list('phases', PhaseModel.tryParse),
      teams: reader.list('teams', ChampionshipTeamModel.fromJson),
      tables: reader.list('tables', ChampionshipTableModel.tryParse),
      rounds: reader.list('rounds', ChampionshipRoundModel.tryParse),
    );
  }
}

class PhaseModel {
  final ChampionshipPhase phase;
  final PhaseStatus status;

  const PhaseModel({required this.phase, required this.status});

  /// Null si la etapa es una que esta versión de la app no conoce: `JsonReader.list` la descarta.
  static PhaseModel? tryParse(Map<String, dynamic> json) {
    final reader = JsonReader(json, resource: 'etapa');
    final phase = ChampionshipPhase.fromApi(reader.optionalString('phase'));
    if (phase == null) return null;
    return PhaseModel(
      phase: phase,
      status: PhaseStatus.fromApi(reader.optionalString('status')),
    );
  }
}

class NextStepModel {
  final ChampionshipAction? action;
  final int pendingMatches;
  final int registeredTeams;
  final int requiredTeams;

  const NextStepModel({
    required this.action,
    this.pendingMatches = 0,
    this.registeredTeams = 0,
    this.requiredTeams = 0,
  });

  factory NextStepModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, resource: 'siguiente paso');
    return NextStepModel(
      action: ChampionshipAction.fromApi(reader.optionalString('action')),
      // Una cuenta que no llega es que no hay nada que contar: cero.
      pendingMatches: reader.optionalInt('pendingMatches') ?? 0,
      registeredTeams: reader.optionalInt('registeredTeams') ?? 0,
      requiredTeams: reader.optionalInt('requiredTeams') ?? 0,
    );
  }
}

class ChampionshipTeamModel {
  final String teamId;
  final String teamName;
  final int? groupNumber;
  final int? seed;

  const ChampionshipTeamModel({
    required this.teamId,
    required this.teamName,
    this.groupNumber,
    this.seed,
  });

  factory ChampionshipTeamModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, resource: 'equipo del campeonato');
    return ChampionshipTeamModel(
      teamId: reader.requiredString('teamId'),
      teamName: reader.requiredString('teamName'),
      groupNumber: reader.optionalInt('groupNumber'),
      seed: reader.optionalInt('seed'),
    );
  }
}

/// La tabla de puntos de una etapa; en la fase de grupos hay una por grupo.
class ChampionshipTableModel {
  final ChampionshipPhase phase;
  final int? groupNumber;
  final List<ChampionshipTableEntryModel> entries;

  const ChampionshipTableModel({
    required this.phase,
    this.groupNumber,
    required this.entries,
  });

  /// Null si la tabla es de una etapa que esta versión de la app no conoce: se descarta en vez de pintarla como otra.
  static ChampionshipTableModel? tryParse(Map<String, dynamic> json) {
    final reader = JsonReader(json, resource: 'tabla del campeonato');
    final phase = ChampionshipPhase.fromApi(reader.optionalString('phase'));
    if (phase == null) return null;
    return ChampionshipTableModel(
      phase: phase,
      groupNumber: reader.optionalInt('groupNumber'),
      entries: reader.list('entries', ChampionshipTableEntryModel.fromJson),
    );
  }
}

class ChampionshipTableEntryModel {
  final int position;
  final String teamId;
  final String teamName;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;

  const ChampionshipTableEntryModel({
    required this.position,
    required this.teamId,
    required this.teamName,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
  });

  factory ChampionshipTableEntryModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, resource: 'fila de la tabla');
    return ChampionshipTableEntryModel(
      position: reader.requiredInt('position'),
      teamId: reader.requiredString('teamId'),
      teamName: reader.requiredString('teamName'),
      played: reader.requiredInt('played'),
      won: reader.requiredInt('won'),
      drawn: reader.requiredInt('drawn'),
      lost: reader.requiredInt('lost'),
      goalsFor: reader.requiredInt('goalsFor'),
      goalsAgainst: reader.requiredInt('goalsAgainst'),
      goalDifference: reader.requiredInt('goalDifference'),
      points: reader.requiredInt('points'),
    );
  }
}

class ChampionshipRoundModel {
  final ChampionshipPhase phase;
  final int roundNumber;
  final int? groupNumber;
  final List<TieModel> ties;

  const ChampionshipRoundModel({
    required this.phase,
    required this.roundNumber,
    this.groupNumber,
    required this.ties,
  });

  /// Null si la ronda es de una etapa que esta versión de la app no conoce: se descarta en vez de pintarla como otra.
  static ChampionshipRoundModel? tryParse(Map<String, dynamic> json) {
    final reader = JsonReader(json, resource: 'ronda del campeonato');
    final phase = ChampionshipPhase.fromApi(reader.optionalString('phase'));
    if (phase == null) return null;
    return ChampionshipRoundModel(
      phase: phase,
      roundNumber: reader.requiredInt('roundNumber'),
      groupNumber: reader.optionalInt('groupNumber'),
      ties: reader.list('ties', TieModel.fromJson),
    );
  }
}

/// Un partido, o los dos partidos de ida y vuelta, entre dos equipos.
class TieModel {
  final int tieNumber;
  final MatchStage? stage;
  final String? teamAId;

  /// Null en la primera ronda de una eliminatoria cuando [bye] es verdadero.
  final String? teamBId;

  /// El equipo avanza sin jugar (pase directo).
  final bool bye;
  final int teamAGoals;
  final int teamBGoals;
  final String? winnerTeamId;
  final bool needsTiebreak;
  final List<LegModel> legs;

  const TieModel({
    required this.tieNumber,
    this.stage,
    this.teamAId,
    this.teamBId,
    this.bye = false,
    this.teamAGoals = 0,
    this.teamBGoals = 0,
    this.winnerTeamId,
    this.needsTiebreak = false,
    this.legs = const [],
  });

  /// El cruce tiene al menos un partido con resultado.
  bool get hasResult => legs.any((leg) => leg.homeScore != null && leg.awayScore != null);

  factory TieModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, resource: 'cruce');
    return TieModel(
      tieNumber: reader.requiredInt('tieNumber'),
      stage: MatchStage.fromApi(reader.optionalString('stage')),
      teamAId: reader.optionalString('teamAId'),
      teamBId: reader.optionalString('teamBId'),
      bye: reader.flag('bye'),
      // Un cruce que aún no se juega no manda goles: cero.
      teamAGoals: reader.optionalInt('teamAGoals') ?? 0,
      teamBGoals: reader.optionalInt('teamBGoals') ?? 0,
      winnerTeamId: reader.optionalString('winnerTeamId'),
      needsTiebreak: reader.flag('needsTiebreak'),
      legs: reader.list('legs', LegModel.fromJson),
    );
  }
}

class LegModel {
  final String matchId;
  final String? homeTeamId;
  final String? awayTeamId;
  final int? homeScore;
  final int? awayScore;
  final int? legNumber;
  final DateTime? matchDate;

  const LegModel({
    required this.matchId,
    this.homeTeamId,
    this.awayTeamId,
    this.homeScore,
    this.awayScore,
    this.legNumber,
    this.matchDate,
  });

  factory LegModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, resource: 'partido del cruce');
    return LegModel(
      matchId: reader.requiredString('matchId'),
      homeTeamId: reader.optionalString('homeTeamId'),
      awayTeamId: reader.optionalString('awayTeamId'),
      homeScore: reader.optionalInt('homeScore'),
      awayScore: reader.optionalInt('awayScore'),
      legNumber: reader.optionalInt('legNumber'),
      matchDate: reader.optionalDateTime('matchDate'),
    );
  }
}
