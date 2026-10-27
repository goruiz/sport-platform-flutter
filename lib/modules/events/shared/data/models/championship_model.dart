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
    return ChampionshipModel(
      eventId: json['eventId']?.toString() ?? '',
      formatName: json['formatName']?.toString(),
      structure: EventFormatStructure.fromApi(json['structure']?.toString()),
      scheduleConfigured: json['scheduleConfigured'] == true,
      groupsDrawn: json['groupsDrawn'] == true,
      teamsAdvancingPerTable: _asInt(json['teamsAdvancingPerTable']),
      championTeamId: json['championTeamId']?.toString(),
      nextStep: json['nextStep'] is Map<String, dynamic>
          ? NextStepModel.fromJson(json['nextStep'] as Map<String, dynamic>)
          : null,
      phases: _asList(json['phases'], PhaseModel.tryParse),
      teams: _asList(json['teams'], ChampionshipTeamModel.fromJson),
      tables: _asList(json['tables'], ChampionshipTableModel.fromJson),
      rounds: _asList(json['rounds'], ChampionshipRoundModel.fromJson),
    );
  }
}

class PhaseModel {
  final ChampionshipPhase phase;
  final PhaseStatus status;

  const PhaseModel({required this.phase, required this.status});

  /// Null si la etapa es una que esta versión de la app no conoce: [_asList] la descarta.
  static PhaseModel? tryParse(Map<String, dynamic> json) {
    final phase = ChampionshipPhase.fromApi(json['phase']?.toString());
    if (phase == null) return null;
    return PhaseModel(
      phase: phase,
      status: PhaseStatus.fromApi(json['status']?.toString()),
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

  factory NextStepModel.fromJson(Map<String, dynamic> json) => NextStepModel(
        action: ChampionshipAction.fromApi(json['action']?.toString()),
        pendingMatches: _asInt(json['pendingMatches']) ?? 0,
        registeredTeams: _asInt(json['registeredTeams']) ?? 0,
        requiredTeams: _asInt(json['requiredTeams']) ?? 0,
      );
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

  factory ChampionshipTeamModel.fromJson(Map<String, dynamic> json) =>
      ChampionshipTeamModel(
        teamId: json['teamId']?.toString() ?? '',
        teamName: json['teamName']?.toString() ?? '',
        groupNumber: _asInt(json['groupNumber']),
        seed: _asInt(json['seed']),
      );
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

  factory ChampionshipTableModel.fromJson(Map<String, dynamic> json) =>
      ChampionshipTableModel(
        phase: ChampionshipPhase.fromApi(json['phase']?.toString()) ??
            ChampionshipPhase.league,
        groupNumber: _asInt(json['groupNumber']),
        entries: _asList(json['entries'], ChampionshipTableEntryModel.fromJson),
      );
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

  factory ChampionshipTableEntryModel.fromJson(Map<String, dynamic> json) =>
      ChampionshipTableEntryModel(
        position: _asInt(json['position']) ?? 0,
        teamId: json['teamId']?.toString() ?? '',
        teamName: json['teamName']?.toString() ?? '',
        played: _asInt(json['played']) ?? 0,
        won: _asInt(json['won']) ?? 0,
        drawn: _asInt(json['drawn']) ?? 0,
        lost: _asInt(json['lost']) ?? 0,
        goalsFor: _asInt(json['goalsFor']) ?? 0,
        goalsAgainst: _asInt(json['goalsAgainst']) ?? 0,
        goalDifference: _asInt(json['goalDifference']) ?? 0,
        points: _asInt(json['points']) ?? 0,
      );
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

  factory ChampionshipRoundModel.fromJson(Map<String, dynamic> json) =>
      ChampionshipRoundModel(
        phase: ChampionshipPhase.fromApi(json['phase']?.toString()) ??
            ChampionshipPhase.knockout,
        roundNumber: _asInt(json['roundNumber']) ?? 0,
        groupNumber: _asInt(json['groupNumber']),
        ties: _asList(json['ties'], TieModel.fromJson),
      );
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

  factory TieModel.fromJson(Map<String, dynamic> json) => TieModel(
        tieNumber: _asInt(json['tieNumber']) ?? 0,
        stage: MatchStage.fromApi(json['stage']?.toString()),
        teamAId: json['teamAId']?.toString(),
        teamBId: json['teamBId']?.toString(),
        bye: json['bye'] == true,
        teamAGoals: _asInt(json['teamAGoals']) ?? 0,
        teamBGoals: _asInt(json['teamBGoals']) ?? 0,
        winnerTeamId: json['winnerTeamId']?.toString(),
        needsTiebreak: json['needsTiebreak'] == true,
        legs: _asList(json['legs'], LegModel.fromJson),
      );
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

  factory LegModel.fromJson(Map<String, dynamic> json) => LegModel(
        matchId: json['matchId']?.toString() ?? '',
        homeTeamId: json['homeTeamId']?.toString(),
        awayTeamId: json['awayTeamId']?.toString(),
        homeScore: _asInt(json['homeScore']),
        awayScore: _asInt(json['awayScore']),
        legNumber: _asInt(json['legNumber']),
        matchDate: json['matchDate'] != null
            ? DateTime.tryParse(json['matchDate'].toString())
            : null,
      );
}

int? _asInt(dynamic value) => value is num ? value.toInt() : null;

/// Lee una lista del JSON; lo que no sea una lista de objetos se toma como vacío y lo que [parse]
/// no sepa leer (devuelve null) se descarta.
List<T> _asList<T>(dynamic value, T? Function(Map<String, dynamic>) parse) {
  if (value is! List) return const [];
  return value.whereType<Map<String, dynamic>>().map(parse).whereType<T>().toList();
}
