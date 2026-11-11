import 'package:sport_platform/core/network/api_error_codes.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/matches/data/models/match_dispute_model.dart';

/// Lo más largo que puede ser lo que el equipo cuenta (el mismo límite que el backend: `REASON_MAX_LENGTH`).
const int disputeReasonMaxLength = 1000;

/// Por qué el backend rechaza un aviso de problema con el resultado (`DisputeError`), con la frase que se le muestra.
enum MatchDisputeError {
  resultNotRecorded('RESULT_NOT_RECORDED'),
  windowClosed('WINDOW_CLOSED'),
  teamNotInMatch('TEAM_NOT_IN_MATCH'),
  notAllowedForTeam('NOT_ALLOWED_FOR_TEAM'),
  alreadyOpen('ALREADY_OPEN'),
  reasonRequired('REASON_REQUIRED'),
  scoreIncomplete('SCORE_INCOMPLETE'),
  invalidScore('INVALID_SCORE');

  const MatchDisputeError(this.backendCode);

  final String backendCode;

  String get translationKey => 'match_detail.dispute.errors.$backendCode';

  /// El rechazo que dijo el backend; null si fue por otra cosa.
  static MatchDisputeError? fromBackend(ApiErrorCodes codes) => codes.firstOf(values, (error) => error.backendCode);
}

/// Solo un partido con resultado puede tener un problema con ese resultado.
bool canReportResultProblem(MatchModel match) => match.hasScore;

/// Los avisos del equipo [teamId], de más nuevo a más antiguo.
List<MatchDisputeModel> disputesOfTeam(Iterable<MatchDisputeModel> disputes, String teamId) =>
    disputes.where((dispute) => dispute.teamId == teamId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

/// Ya hay un aviso esperando respuesta: no se puede abrir otro hasta que el organizador responda.
bool hasOpenDispute(Iterable<MatchDisputeModel> disputes) => disputes.any((dispute) => dispute.isOpen);

/// Lo que va a mostrar la tarjeta del partido: el aviso más reciente (uno abierto manda sobre los ya respondidos) y si se
/// puede mandar otro. El backend decide si todavía hay tiempo: esto solo evita ofrecer un segundo aviso abierto.
class DisputeCardState {
  final MatchDisputeModel? latest;
  final bool canOpenNew;

  const DisputeCardState({this.latest, required this.canOpenNew});

  factory DisputeCardState.of(List<MatchDisputeModel> myTeamDisputes) {
    // La lista ya viene de más nuevo a más antiguo: el aviso abierto, si lo hay, es lo que importa mostrar.
    final open = myTeamDisputes.where((dispute) => dispute.isOpen);
    final latest = open.isNotEmpty
        ? open.first
        : (myTeamDisputes.isEmpty ? null : myTeamDisputes.first);
    return DisputeCardState(latest: latest, canOpenNew: !hasOpenDispute(myTeamDisputes));
  }
}

/// Por qué el marcador que el equipo propone no sirve.
enum ProposedScoreProblem {
  /// Escribió los goles de un solo equipo.
  incomplete,

  /// No es un número entero desde 0.
  invalid,
}

/// El marcador que el equipo cree correcto, ya leído de las dos casillas. Ambas vacías es válido: el marcador es opcional.
class ProposedScoreInput {
  final int? homeScore;
  final int? awayScore;
  final ProposedScoreProblem? problem;

  const ProposedScoreInput({this.homeScore, this.awayScore, this.problem});

  bool get isValid => problem == null;
}

/// Lee las dos casillas del marcador propuesto: las dos vacías (sin propuesta) o las dos con un entero desde 0.
ProposedScoreInput readProposedScore(String homeText, String awayText) {
  final home = homeText.trim();
  final away = awayText.trim();
  if (home.isEmpty && away.isEmpty) return const ProposedScoreInput();
  if (home.isEmpty || away.isEmpty) return const ProposedScoreInput(problem: ProposedScoreProblem.incomplete);
  final homeScore = _readGoals(home);
  final awayScore = _readGoals(away);
  if (homeScore == null || awayScore == null) return const ProposedScoreInput(problem: ProposedScoreProblem.invalid);
  return ProposedScoreInput(homeScore: homeScore, awayScore: awayScore);
}

/// Un número entero sin signo (`+`, `-`) ni decimales; null si no lo es.
int? _readGoals(String text) => RegExp(r'^\d+$').hasMatch(text) ? int.tryParse(text) : null;
