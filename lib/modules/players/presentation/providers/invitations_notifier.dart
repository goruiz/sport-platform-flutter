import 'package:flutter/foundation.dart';
import 'package:sport_platform/modules/players/data/datasource/team_invitations_service.dart';
import 'package:sport_platform/modules/players/data/models/team_invitation_model.dart';
import 'package:sport_platform/modules/players/domain/enums/team_invitation_error.dart';

/// Las invitaciones pendientes del usuario. Lo comparten el inicio (tarjeta y campana con su
/// contador) y la bandeja, por eso vive en GetIt y se reinicia al cerrar la sesión.
class InvitationsNotifier extends ChangeNotifier {
  static const _genericErrorKey = 'invitations.error_generic';

  final TeamInvitationsService _service;

  List<TeamInvitationModel> _invitations = [];
  bool _loading = false;
  bool _loadedOnce = false;
  String? _error;

  InvitationsNotifier(this._service);

  List<TeamInvitationModel> get invitations => List.unmodifiable(_invitations);
  int get pendingCount => _invitations.length;
  bool get loading => _loading;

  /// Ya se pidieron al backend al menos una vez: antes de eso «sin invitaciones» sería un engaño.
  bool get loadedOnce => _loadedOnce;

  /// Clave de traducción del último error de carga (no el texto): sigue al idioma activo.
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _invitations = await _service.getMine();
    } catch (_) {
      _error = _genericErrorKey;
    } finally {
      _loading = false;
      _loadedOnce = true;
      notifyListeners();
    }
  }

  /// Acepta la invitación. Si el backend la rechaza devuelve la clave del motivo y vuelve a leer la
  /// lista (la invitación ya no es respondible); null si todo salió bien.
  Future<String?> accept(String invitationId) =>
      _answer(() => _service.accept(invitationId));

  Future<String?> decline(String invitationId) =>
      _answer(() => _service.decline(invitationId));

  Future<String?> _answer(Future<void> Function() answer) async {
    try {
      await answer();
      await load();
      return null;
    } catch (error) {
      final reason = TeamInvitationError.fromException(error);
      await load();
      return reason?.translationKey ?? _genericErrorKey;
    }
  }

  /// Olvida lo del usuario anterior (al cerrar la sesión).
  void clear() {
    _invitations = [];
    _loading = false;
    _loadedOnce = false;
    _error = null;
    notifyListeners();
  }
}
