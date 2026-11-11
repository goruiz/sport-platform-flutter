import 'package:flutter/foundation.dart';
import 'package:sport_platform/core/network/api_error_codes.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/matches/data/datasource/match_disputes_service.dart';
import 'package:sport_platform/modules/matches/data/models/match_dispute_model.dart';
import 'package:sport_platform/modules/matches/domain/match_attendance_rules.dart';
import 'package:sport_platform/modules/matches/domain/match_dispute_rules.dart';
import 'package:sport_platform/modules/users/domain/enums/account_capability.dart';
import 'package:sport_platform/modules/users/presentation/providers/account_capabilities_notifier.dart';
import 'package:sport_platform/shared/enums/summary_status.dart';

/// «¿Hay un problema con el resultado?»: lo que el dirigente de equipo ve de un partido y lo que puede hacer.
///
/// Solo existe para quien tiene la capacidad [AccountCapability.openMatchDisputes] y juega en uno de los dos equipos del
/// partido, y solo cuando el partido ya tiene resultado: para cualquier otra cuenta [isAvailable] es falso y no se pide
/// nada más (los avisos ni siquiera se leen).
class MatchResultDisputeNotifier extends ChangeNotifier {
  static const _loadErrorKey = 'match_detail.dispute.error_load';
  static const _saveErrorKey = 'match_detail.dispute.error_save';

  final AccountCapabilitiesNotifier _capabilities;
  final PlayersService _playersService;
  final MatchDisputesService _service;
  final MatchModel match;

  MatchResultDisputeNotifier({
    required AccountCapabilitiesNotifier capabilities,
    required PlayersService playersService,
    required MatchDisputesService service,
    required this.match,
  }) : _capabilities = capabilities,
       _playersService = playersService,
       _service = service;

  SummaryStatus _status = SummaryStatus.loading;
  bool _isAvailable = false;
  String? _myTeamId;
  List<MatchDisputeModel> _disputes = const [];
  bool _isSaving = false;
  bool _isDisposed = false;

  /// Cuenta las lecturas: la respuesta de una que ya no es la última se descarta.
  int _loadCount = 0;

  SummaryStatus get status => _status;

  /// La cuenta puede avisar de un problema con este partido: solo así se le muestra la tarjeta.
  bool get isAvailable => _isAvailable;

  /// El equipo del dirigente en el partido; null si no puede avisar.
  String? get myTeamId => _isAvailable ? _myTeamId : null;

  /// Los avisos de su equipo, de más nuevo a más antiguo.
  List<MatchDisputeModel> get disputes => _disputes;

  /// Se está enviando un aviso: no se puede mandar otro todavía.
  bool get isSaving => _isSaving;

  /// La clave de traducción del error de la lectura; null si no falló.
  String? get loadErrorKey => _status == SummaryStatus.failed ? _loadErrorKey : null;

  /// [forceCapabilities] vuelve a leer lo que la cuenta puede hacer (al actualizar la pantalla a mano: el administrador
  /// pudo cambiarle el rol); la primera lectura de la sesión se reutiliza.
  Future<void> load({bool forceCapabilities = false}) async {
    final loadId = ++_loadCount;
    _status = SummaryStatus.loading;
    _notify();
    var status = SummaryStatus.ready;
    var isAvailableNow = false;
    String? teamId;
    var disputes = const <MatchDisputeModel>[];
    try {
      if (forceCapabilities) await _capabilities.refresh();
      await _capabilities.ensureLoaded();
      if (_capabilities.can(AccountCapability.openMatchDisputes) && canReportResultProblem(match)) {
        final player = await _playersService.getCurrent();
        // De sus equipos (puede jugar en varios), el que juega este partido.
        teamId = player == null ? null : teamOfPlayerInMatch(match, player.teamIds);
        if (teamId != null) {
          isAvailableNow = true;
          disputes = disputesOfTeam(await _service.getByMatch(match.id), teamId);
        }
      }
    } catch (_) {
      status = SummaryStatus.failed;
    }
    if (loadId != _loadCount) return;
    _myTeamId = teamId;
    _isAvailable = isAvailableNow;
    _disputes = disputes;
    _status = status;
    _notify();
  }

  /// Avisa de que el resultado está mal. Devuelve la clave de traducción del problema si no se pudo, o null si salió bien.
  Future<String?> report({required String reason, int? proposedHomeScore, int? proposedAwayScore}) async {
    final teamId = _myTeamId;
    if (_isSaving || teamId == null) return null;
    _isSaving = true;
    _notify();
    try {
      final dispute = await _service.open(
        match.id,
        teamId: teamId,
        reason: reason,
        proposedHomeScore: proposedHomeScore,
        proposedAwayScore: proposedAwayScore,
      );
      if (dispute != null) _disputes = [dispute, ..._disputes];
      return null;
    } catch (error) {
      return MatchDisputeError.fromBackend(ApiErrorCodes.of(error))?.translationKey ?? _saveErrorKey;
    } finally {
      _isSaving = false;
      _notify();
    }
  }

  /// Una operación que termina después de cerrar la pantalla no debe avisar a nadie.
  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
