import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sport_platform/core/services/active_team_storage.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/teams/domain/team_members.dart';

/// El equipo que el jugador está viendo. Quien juega en varios (uno por organización) elige uno y TODA la app (inicio,
/// partidos, reportes, rankings) muestra lo de ese equipo; con uno solo, ese es siempre el activo.
///
/// Cada pantalla ya lee al jugador por su cuenta: le pasa lo que leyó a [sync], que anota sus equipos y devuelve el
/// activo. La elección se guarda en el dispositivo y se descarta al cerrar la sesión ([clear]).
///
/// Quien dependa del equipo activo escucha este notificador y vuelve a leer **solo si cambió su id**: también avisa
/// cuando cambia la lista de equipos (para que el selector la refleje), y eso no debe recargar nada.
class ActiveTeamNotifier extends ChangeNotifier {
  List<PlayerTeam> _teams = const [];
  String? _activeTeamId;

  /// Su lugar en la lista: si el jugador abandona el equipo activo, queda activo el que ocupa ahora ese lugar.
  int _activeIndex = 0;

  /// La lectura de lo guardado, una sola vez: varias pantallas pueden pedir [sync] a la vez al abrir la app.
  Future<void>? _restoring;

  /// Todos los equipos del jugador, el último al que entró primero.
  List<PlayerTeam> get teams => List.unmodifiable(_teams);

  bool get hasSeveralTeams => _teams.length > 1;

  /// El id del equipo que se ve; null mientras no se sepa o si el jugador no tiene equipo.
  String? get activeTeamId => _activeTeamId;

  PlayerTeam? get activeTeam {
    for (final team in _teams) {
      if (team.teamId == _activeTeamId) return team;
    }
    return null;
  }

  /// Anota los equipos de [player] (que quien llama acaba de leer) y devuelve el equipo activo: el que el jugador eligió si
  /// sigue siendo suyo; si lo abandonó, el que ocupa ahora su lugar; y mientras no haya elegido, el último al que entró.
  Future<PlayerTeam?> sync(PlayerModel? player) async {
    await (_restoring ??= _restoreStoredTeamId());
    final previousTeams = _teams;
    final previousId = _activeTeamId;

    _teams = player?.allTeams ?? const [];
    _pickActiveTeam();

    if (_activeTeamId != previousId) unawaited(_persistActiveTeam());
    // Cambió lo que se ve (o la lista de equipos): se avisa. Pasar de «no sé» al primer equipo no es un cambio.
    final changedActiveTeam = previousId != null && _activeTeamId != previousId;
    if (changedActiveTeam || !_sameTeams(previousTeams, _teams)) notifyListeners();
    return activeTeam;
  }

  /// El jugador elige ver [teamId] (uno de los suyos); lo demás sale de ahí.
  void select(String teamId) {
    final index = _teams.indexWhere((team) => team.teamId == teamId);
    if (index < 0 || teamId == _activeTeamId) return;
    _activeTeamId = teamId;
    _activeIndex = index;
    unawaited(_persistActiveTeam());
    notifyListeners();
  }

  /// Al cerrar la sesión: se olvida todo, también lo guardado.
  void clear() {
    _teams = const [];
    _activeTeamId = null;
    _activeIndex = 0;
    _restoring = null;
    unawaited(ActiveTeamStorage.clear());
  }

  void _pickActiveTeam() {
    final ids = [for (final team in _teams) team.teamId];
    if (ids.isEmpty) {
      _activeTeamId = null;
      _activeIndex = 0;
      return;
    }
    final id = pickSelectedTeamId(ids, previousId: _activeTeamId, previousIndex: _activeIndex);
    _activeTeamId = id;
    _activeIndex = ids.indexOf(id);
  }

  Future<void> _restoreStoredTeamId() async {
    // Si alguien ya eligió mientras se leía lo guardado, esa elección manda.
    _activeTeamId ??= await ActiveTeamStorage.load();
  }

  Future<void> _persistActiveTeam() async {
    final id = _activeTeamId;
    if (id == null) {
      await ActiveTeamStorage.clear();
    } else {
      await ActiveTeamStorage.save(id);
    }
  }

  bool _sameTeams(List<PlayerTeam> a, List<PlayerTeam> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index].teamId != b[index].teamId || a[index].teamName != b[index].teamName) return false;
    }
    return true;
  }
}
