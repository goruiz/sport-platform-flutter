import 'package:flutter/foundation.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/courts_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/court_model.dart';
import 'package:sport_platform/modules/events/shared/data/datasource/team_events_service.dart';
import 'package:sport_platform/modules/events/shared/domain/event_rules.dart';
import 'package:sport_platform/modules/sport_complexes/data/datasource/sport_complexes_service.dart';
import 'package:sport_platform/modules/sport_complexes/domain/complex_overview.dart';
import 'package:sport_platform/modules/teams/presentation/providers/active_team_notifier.dart';

/// De qué complejos se habla: los de los eventos del equipo activo del jugador o todos los que ve.
enum ComplexesScope { myTeam, all }

/// El estado de la pantalla «Complejos y canchas»: cada complejo con sus canchas. Abre con los complejos donde se juegan
/// los eventos del equipo activo (el que el jugador eligió en «Equipo»; sin equipo, con todos los que ve) y se vuelve a
/// armar al cambiarlo ([ActiveTeamNotifier]).
///
/// Los complejos y las canchas se leen una vez por carga; los eventos de cada equipo, una vez por equipo: cambiar de equipo
/// o de alcance no vuelve a pedir lo que ya se leyó. Descarta la respuesta de una lectura que ya no es la actual, para que
/// una respuesta lenta nunca pise a una más nueva.
class SportComplexesNotifier extends ChangeNotifier {
  static const _loadErrorKey = 'mobile.complexes.load_error';

  final SportComplexesService _complexesService;
  final CourtsService _courtsService;
  final TeamEventsService _teamEventsService;
  final PlayersService _playersService;
  final ActiveTeamNotifier _activeTeam;

  SportComplexesNotifier({
    required SportComplexesService complexesService,
    required CourtsService courtsService,
    required TeamEventsService teamEventsService,
    required PlayersService playersService,
    required ActiveTeamNotifier activeTeam,
  })  : _complexesService = complexesService,
        _courtsService = courtsService,
        _teamEventsService = teamEventsService,
        _playersService = playersService,
        _activeTeam = activeTeam {
    _activeTeam.addListener(_onActiveTeamChanged);
  }

  /// El equipo activo cuya lectura está en curso o terminó por última vez: lo que se compara para saber si cambió. Null
  /// mientras llega la primera o si el jugador no tiene equipo.
  String? _watchedTeamId;

  ComplexesScope _scope = ComplexesScope.all;

  /// Aún no se ha leído nada: la primera lectura es la que elige el alcance con que se abre.
  bool _isFirstLoad = true;

  /// Todos los complejos que el jugador ve, con sus canchas, y las canchas sin complejo; null hasta leerlos.
  List<ComplexOverview>? _allOverviews;
  List<CourtModel> _courtsWithoutComplex = const [];

  /// Los complejos donde se juegan los eventos de cada equipo ya leídos, por id de equipo.
  final Map<String, Set<String>> _complexIdsByTeam = {};

  bool _loading = false;
  String? _error;

  /// Cada lectura nueva sube el número: una respuesta que llega con otro número ya no es de la lectura actual.
  int _readGeneration = 0;
  bool _isDisposed = false;

  ComplexesScope get scope => _scope;

  /// El jugador tiene un equipo activo: solo entonces hay «Mi equipo» que elegir.
  bool get hasTeam => _activeTeam.activeTeamId != null;

  bool get loading => _loading;

  /// Clave de traducción del último error (no el texto): sigue al idioma activo.
  String? get error => _error;

  /// Todavía no hay nada que enseñar (se está leyendo por primera vez o falló).
  bool get hasNothingYet => _allOverviews == null;

  /// Los complejos de este alcance con sus canchas, por nombre: los de los eventos del equipo activo o todos.
  List<ComplexOverview> get overviews {
    final all = _allOverviews ?? const <ComplexOverview>[];
    final teamId = _scopedTeamId;
    if (teamId == null) return all;
    return filterComplexOverviewsByIds(all, _complexIdsByTeam[teamId] ?? const {});
  }

  /// Las canchas que no son de ningún complejo; solo se ofrecen en «Todos»: ningún evento las tiene asignadas.
  List<CourtModel> get courtsWithoutComplex =>
      _scopedTeamId == null ? List.unmodifiable(_courtsWithoutComplex) : const [];

  /// El equipo cuyos eventos mandan: el activo en «Mi equipo»; en «Todos» (o sin equipo) ninguno.
  String? get _scopedTeamId => _scope == ComplexesScope.myTeam ? _activeTeam.activeTeamId : null;

  /// Lee al jugador (para saber cuál es su equipo activo) y arma la lista desde el principio. Al abrir muestra los
  /// complejos de los eventos de ese equipo (o todos, si no tiene); al actualizar conserva lo que el jugador eligió.
  Future<void> load() async {
    _loading = true;
    _error = null;
    _notify();
    await _syncActiveTeam();
    _allOverviews = null;
    _courtsWithoutComplex = const [];
    _complexIdsByTeam.clear();
    if (_isFirstLoad) _scope = hasTeam ? ComplexesScope.myTeam : ComplexesScope.all;
    if (!hasTeam) _scope = ComplexesScope.all;
    _isFirstLoad = false;
    await _read();
  }

  Future<void> selectScope(ComplexesScope scope) {
    if (scope == _scope || (scope == ComplexesScope.myTeam && !hasTeam)) return Future.value();
    _scope = scope;
    return _read();
  }

  /// Anota los equipos del jugador, que dicen cuál es el activo. Si no se lo puede leer se sigue con el equipo que la app ya
  /// tenía (y, sin él, con todos los complejos): no se bloquea la pantalla por eso.
  Future<void> _syncActiveTeam() async {
    try {
      await _activeTeam.sync(await _playersService.getCurrent());
    } catch (_) {
      // Sin el jugador no se sabe más: se queda con lo que hay.
    }
    _watchedTeamId = _activeTeam.activeTeamId;
  }

  /// El jugador eligió ver otro de sus equipos: se leen los eventos del nuevo. Los avisos que no cambian el equipo activo
  /// (la lista de equipos, por ejemplo) no recargan nada.
  void _onActiveTeamChanged() {
    final activeTeamId = _activeTeam.activeTeamId;
    final watchedTeamId = _watchedTeamId;
    if (watchedTeamId == null || activeTeamId == watchedTeamId) return;
    _watchedTeamId = activeTeamId;
    if (activeTeamId == null) _scope = ComplexesScope.all;
    if (_scope == ComplexesScope.myTeam || activeTeamId == null) _read();
  }

  /// Deja leído lo que el alcance actual necesita: el catálogo de complejos y canchas y, en «Mi equipo», los eventos del
  /// equipo activo. Lo ya leído no se vuelve a pedir.
  Future<void> _read() async {
    final generation = ++_readGeneration;
    _loading = true;
    _error = null;
    _notify();
    try {
      final catalog = _allOverviews == null ? await _readCatalog() : null;
      final teamId = _scopedTeamId;
      final teamComplexIds = teamId == null || _complexIdsByTeam.containsKey(teamId)
          ? null
          : await _readComplexIdsOfTeam(teamId);
      if (generation != _readGeneration) return;
      if (catalog != null) {
        _allOverviews = catalog.overviews;
        _courtsWithoutComplex = catalog.courtsWithoutComplex;
      }
      if (teamComplexIds != null) _complexIdsByTeam[teamId!] = teamComplexIds;
    } catch (_) {
      if (generation != _readGeneration) return;
      _error = _loadErrorKey;
    } finally {
      if (generation == _readGeneration) {
        _loading = false;
        _notify();
      }
    }
  }

  /// Los complejos y las canchas salen a la vez; se espera cada lectura por separado para conservar su tipo.
  Future<({List<ComplexOverview> overviews, List<CourtModel> courtsWithoutComplex})> _readCatalog() async {
    final complexesRead = _complexesService.getAll();
    final courtsRead = _courtsService.getAll();
    final complexes = await complexesRead;
    final courts = await courtsRead;
    return (
      overviews: buildComplexOverviews(complexes, courts),
      courtsWithoutComplex: listCourtsWithoutComplex(courts),
    );
  }

  Future<Set<String>> _readComplexIdsOfTeam(String teamId) async =>
      sportComplexIdsOfEvents(await _teamEventsService.getOfTeam(teamId));

  /// Una lectura que termina después de cerrar la pantalla no debe avisar a nadie.
  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _activeTeam.removeListener(_onActiveTeamChanged);
    super.dispose();
  }
}
