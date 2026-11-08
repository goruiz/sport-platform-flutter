import 'package:flutter/foundation.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/rankings/data/datasource/player_stats_service.dart';
import 'package:sport_platform/modules/rankings/data/models/player_stats_model.dart';
import 'package:sport_platform/shared/enums/summary_status.dart';

// Las pantallas y pruebas del perfil siguen importando el estado de lectura desde aquí.
export 'package:sport_platform/shared/enums/summary_status.dart';

/// Lo que el perfil muestra además de los datos de la cuenta: el equipo del jugador (y si es capitán) y sus
/// estadísticas, sumadas por el backend en todos los eventos en que ha jugado (también con un equipo anterior).
class ProfileSummaryNotifier extends ChangeNotifier {
  final PlayersService _playersService;
  final PlayerStatsService _playerStatsService;

  ProfileSummaryNotifier({
    required PlayersService playersService,
    required PlayerStatsService playerStatsService,
  }) : _playersService = playersService,
       _playerStatsService = playerStatsService;

  SummaryStatus _teamStatus = SummaryStatus.loading;
  SummaryStatus _statsStatus = SummaryStatus.loading;
  PlayerModel? _player;
  PlayerStatsModel? _totals;

  /// Cuenta las lecturas: la respuesta de una que ya no es la última (el usuario refrescó) se descarta.
  int _loadCount = 0;
  bool _isDisposed = false;

  SummaryStatus get teamStatus => _teamStatus;
  SummaryStatus get statsStatus => _statsStatus;

  /// El jugador de la cuenta; null si la cuenta aún no tiene o no se pudo leer.
  PlayerModel? get player => _player;

  /// El jugador pertenece a un equipo.
  bool get hasTeam => _player?.teamId?.isNotEmpty ?? false;

  /// Lo sumado en todos los eventos; null si aún no tiene partidos jugados ni goles, tarjetas ni faltas.
  PlayerStatsModel? get totalStats => _totals;

  /// Cambia el jugador mostrado por uno más nuevo (por ejemplo, tras cambiar su foto) sin volver a leer nada.
  void replacePlayer(PlayerModel player) {
    _player = player;
    _notify();
  }

  Future<void> load() async {
    final loadId = ++_loadCount;
    _teamStatus = SummaryStatus.loading;
    _statsStatus = SummaryStatus.loading;
    _notify();

    final PlayerModel? player;
    try {
      player = await _playersService.getCurrent();
    } catch (_) {
      if (loadId == _loadCount) _failTeam();
      return;
    }
    if (loadId != _loadCount) return;

    _player = player;
    _teamStatus = SummaryStatus.ready;
    if (player == null || !hasTeam) {
      _totals = null;
      _statsStatus = SummaryStatus.ready;
      _notify();
      return;
    }
    // El equipo ya se puede mostrar mientras llegan las estadísticas, que piden más lecturas.
    _notify();
    await _loadStats(player, loadId);
  }

  void _failTeam() {
    _player = null;
    _totals = null;
    _teamStatus = SummaryStatus.failed;
    _statsStatus = SummaryStatus.failed;
    _notify();
  }

  Future<void> _loadStats(PlayerModel player, int loadId) async {
    PlayerStatsModel? totals;
    var status = SummaryStatus.ready;
    try {
      totals = await _readTotals();
    } catch (_) {
      status = SummaryStatus.failed;
    }
    if (loadId != _loadCount) return;
    _totals = totals;
    _statsStatus = status;
    _notify();
  }

  Future<PlayerStatsModel?> _readTotals() async {
    final totals = await _playerStatsService.getMine();
    return totals.isEmpty ? null : totals;
  }

  /// Una lectura que termina después de cerrar la pantalla no debe avisar a nadie.
  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
