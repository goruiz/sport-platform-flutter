import 'package:flutter/foundation.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/matches/data/datasource/matches_service.dart';
import 'package:sport_platform/modules/rankings/data/datasource/player_stats_service.dart';
import 'package:sport_platform/modules/rankings/data/models/player_stats_model.dart';
import 'package:sport_platform/shared/enums/summary_status.dart';

/// Una lectura de la pantalla con su propio estado, para que una que falla no tape a las demás.
class _Section<T> {
  /// Lo que vale la sección mientras no hay nada leído o si la lectura falla.
  final T emptyValue;

  SummaryStatus status = SummaryStatus.loading;
  late T value = emptyValue;

  /// Cuenta las lecturas: la respuesta de una que ya no es la última (se refrescó) se descarta.
  int requests = 0;

  _Section(this.emptyValue);
}

/// Lo que se ve de un equipo dentro de un evento: sus partidos, lo que hicieron sus jugadores y su plantilla.
/// Solo se muestra lo que el backend deja ver: de un evento público no se leen los jugadores de otra organización,
/// y esa lectura al fallar no se avisa, porque no es un error (la plantilla simplemente no se ve).
class TeamInEventNotifier extends ChangeNotifier {
  final MatchesService _matchesService;
  final PlayerStatsService _playerStatsService;
  final PlayersService _playersService;
  final String eventId;
  final String teamId;

  TeamInEventNotifier({
    required MatchesService matchesService,
    required PlayerStatsService playerStatsService,
    required PlayersService playersService,
    required this.eventId,
    required this.teamId,
  }) : _matchesService = matchesService,
       _playerStatsService = playerStatsService,
       _playersService = playersService;

  final _matches = _Section<List<MatchModel>>(const []);
  final _stats = _Section<List<PlayerStatsModel>>(const []);
  final _roster = _Section<List<PlayerModel>>(const []);
  bool _isDisposed = false;

  SummaryStatus get matchesStatus => _matches.status;

  /// Todos los partidos del evento (de ahí se sacan los del equipo).
  List<MatchModel> get eventMatches => _matches.value;

  SummaryStatus get statsStatus => _stats.status;

  /// Las estadísticas de todos los jugadores del evento (de ahí se sacan las de este equipo).
  List<PlayerStatsModel> get eventStats => _stats.value;

  SummaryStatus get rosterStatus => _roster.status;

  /// La plantilla; vacía si no se ve.
  List<PlayerModel> get roster => _roster.value;

  Future<void> load() => Future.wait([loadMatches(), loadStats(), _loadRoster()]);

  Future<void> loadMatches() => _read(_matches, () => _matchesService.getByEvent(eventId));

  Future<void> loadStats() => _read(_stats, () => _playerStatsService.getByEvent(eventId));

  /// La plantilla no es un error si no se puede leer: se queda vacía y la pantalla no la muestra.
  Future<void> _loadRoster() async {
    await _read(_roster, () => _playersService.getByTeamId(teamId));
    if (_roster.status == SummaryStatus.failed) {
      _roster.status = SummaryStatus.ready;
      _notify();
    }
  }

  Future<void> _read<T>(_Section<T> section, Future<T> Function() read) async {
    final request = ++section.requests;
    section.status = SummaryStatus.loading;
    _notify();
    T value = section.emptyValue;
    var status = SummaryStatus.ready;
    try {
      value = await read();
    } catch (_) {
      status = SummaryStatus.failed;
    }
    if (request != section.requests) return;
    section.value = value;
    section.status = status;
    _notify();
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
