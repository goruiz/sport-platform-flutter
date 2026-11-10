import 'package:flutter/foundation.dart';
import 'package:sport_platform/core/network/api_error_codes.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/matches/data/datasource/match_attendance_service.dart';
import 'package:sport_platform/modules/matches/data/models/match_attendance_model.dart';
import 'package:sport_platform/modules/matches/domain/match_attendance_rules.dart';
import 'package:sport_platform/shared/enums/summary_status.dart';

/// La asistencia a un partido para quien juega en uno de sus equipos: quiénes van y su propia respuesta.
/// Quien no es de esos equipos no ve nada de esto ([isParticipant] es falso y no se lee la asistencia).
class MatchAttendanceNotifier extends ChangeNotifier {
  static const _loadErrorKey = 'match_detail.attendance.error_load';
  static const _saveErrorKey = 'match_detail.attendance.error_save';

  final PlayersService _playersService;
  final MatchAttendanceService _service;
  final MatchModel match;
  final DateTime Function() _clock;

  MatchAttendanceNotifier({
    required PlayersService playersService,
    required MatchAttendanceService service,
    required this.match,
    DateTime Function()? clock,
  }) : _playersService = playersService,
       _service = service,
       _clock = clock ?? DateTime.now;

  SummaryStatus _status = SummaryStatus.loading;
  bool _isParticipant = false;
  String? _myTeamId;
  MatchAttendanceModel? _attendance;
  bool _isSaving = false;
  bool _isDisposed = false;

  /// Cuenta las lecturas: la respuesta de una que ya no es la última se descarta.
  int _loadCount = 0;

  SummaryStatus get status => _status;

  /// El jugador de la cuenta juega este partido: solo así se le muestra la asistencia.
  bool get isParticipant => _isParticipant;
  MatchAttendanceModel? get attendance => _attendance;

  /// Se está guardando una respuesta: no se puede mandar otra todavía.
  bool get isSaving => _isSaving;

  /// El equipo del jugador en el partido; null si no juega.
  String? get myTeamId => _isParticipant ? _myTeamId : null;

  /// Todavía se puede responder o cambiar la respuesta.
  bool get canAnswer => _isParticipant && canAnswerAttendance(match, _clock());

  Future<void> load() async {
    final loadId = ++_loadCount;
    _status = SummaryStatus.loading;
    _notify();
    var status = SummaryStatus.ready;
    MatchAttendanceModel? attendance;
    var isParticipantNow = false;
    String? teamId;
    try {
      final player = await _playersService.getCurrent();
      // De sus equipos (puede jugar en varios), el que juega este partido: no el activo ni el último al que entró.
      teamId = player == null ? null : teamOfPlayerInMatch(match, player.teamIds);
      isParticipantNow = teamId != null;
      if (isParticipantNow) attendance = await _service.get(match.id);
    } catch (_) {
      status = SummaryStatus.failed;
    }
    if (loadId != _loadCount) return;
    _myTeamId = teamId;
    _isParticipant = isParticipantNow;
    _attendance = attendance;
    _status = status;
    _notify();
  }

  /// Guarda la respuesta del jugador. Devuelve la clave de traducción del problema si no se pudo, o null si salió bien.
  Future<String?> answer(AttendanceStatus status) => _save(() => _service.respond(match.id, status));

  /// Quita la respuesta del jugador.
  Future<String?> clearAnswer() => _save(() => _service.withdraw(match.id));

  Future<String?> _save(Future<MatchAttendanceModel> Function() action) async {
    if (_isSaving) return null;
    _isSaving = true;
    _notify();
    try {
      _attendance = await action();
      return null;
    } catch (error) {
      return MatchAttendanceError.fromBackend(ApiErrorCodes.of(error))?.translationKey ?? _saveErrorKey;
    } finally {
      _isSaving = false;
      _notify();
    }
  }

  /// La clave de traducción del error de la lectura; null si no falló.
  String? get loadErrorKey => _status == SummaryStatus.failed ? _loadErrorKey : null;

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
