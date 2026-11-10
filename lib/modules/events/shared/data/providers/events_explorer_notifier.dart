import 'package:flutter/foundation.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/shared/data/datasource/events_search_service.dart';
import 'package:sport_platform/modules/events/shared/data/datasource/team_events_service.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/event_status.dart';
import 'package:sport_platform/modules/events/shared/domain/event_rules.dart';
import 'package:sport_platform/modules/teams/presentation/providers/active_team_notifier.dart';

/// De qué eventos se habla: los del equipo activo del jugador o todos los que ve.
enum EventsScope { myTeam, all }

/// El estado de la pantalla que explora los eventos: de qué equipo son, lo que se busca, el estado elegido y las páginas que
/// ya se descargaron. Abre con los eventos del equipo activo (el que el jugador eligió en «Equipo»; sin equipo, con todos
/// los que ve) y se vuelve a armar al cambiarlo ([ActiveTeamNotifier]).
///
/// Todos los eventos se piden una página a la vez al backend; los de un equipo son pocos y se leen enteros una vez, así que
/// buscar y filtrar por estado trabajan sobre ellos sin volver a pedir nada. Descarta la respuesta de una lectura que ya no
/// es la actual, para que una respuesta lenta nunca pise a una más nueva.
class EventsExplorerNotifier extends ChangeNotifier {
  static const _loadErrorKey = 'mobile.events.load_error';

  final EventsSearchService _searchService;
  final TeamEventsService _teamEventsService;
  final PlayersService _playersService;
  final ActiveTeamNotifier _activeTeam;

  EventsExplorerNotifier({
    required EventsSearchService searchService,
    required TeamEventsService teamEventsService,
    required PlayersService playersService,
    required ActiveTeamNotifier activeTeam,
  })  : _searchService = searchService,
        _teamEventsService = teamEventsService,
        _playersService = playersService,
        _activeTeam = activeTeam {
    _activeTeam.addListener(_onActiveTeamChanged);
  }

  /// El equipo activo cuya lectura está en curso o terminó por última vez: lo que se compara para saber si cambió. Null
  /// mientras llega la primera o si el jugador no tiene equipo.
  String? _watchedTeamId;

  EventsScope _scope = EventsScope.all;

  /// Aún no se ha leído nada: la primera lectura es la que elige el alcance con que se abre.
  bool _isFirstLoad = true;

  /// Los eventos de cada equipo ya leídos (todos, sin filtrar), por id de equipo. Se descartan al recargar.
  final Map<String, List<EventModel>> _teamEventsById = {};

  String _text = '';
  EventStatus? _status;
  List<EventModel> _events = [];
  int _loadedPages = 0;
  int _totalElements = 0;
  bool _hasMore = false;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;

  /// Cada lectura nueva sube el número: una respuesta que llega con otro número ya no es de la lectura actual.
  int _searchGeneration = 0;
  bool _isDisposed = false;

  EventsScope get scope => _scope;

  /// El jugador tiene un equipo activo: solo entonces hay «Mi equipo» que elegir.
  bool get hasTeam => _activeTeam.activeTeamId != null;

  String get text => _text;
  EventStatus? get status => _status;
  List<EventModel> get events => List.unmodifiable(_events);
  int get totalElements => _totalElements;
  bool get hasMore => _hasMore;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;

  /// Clave de traducción del último error (no el texto): sigue al idioma activo.
  String? get error => _error;

  /// Hay alguna búsqueda o filtro puesto (para decir «sin resultados» en vez de «aún no hay eventos»).
  bool get isFiltering => _text.trim().isNotEmpty || _status != null;

  /// Lee al jugador (para saber cuál es su equipo activo) y arma la lista desde el principio. Al abrir muestra los eventos
  /// de ese equipo (o todos, si no tiene); al actualizar conserva lo que el jugador eligió.
  Future<void> load() async {
    _loading = true;
    _error = null;
    _notify();
    await _syncActiveTeam();
    _teamEventsById.clear();
    if (_isFirstLoad) _scope = hasTeam ? EventsScope.myTeam : EventsScope.all;
    if (!hasTeam) _scope = EventsScope.all;
    _isFirstLoad = false;
    await _reload();
  }

  Future<void> selectScope(EventsScope scope) {
    if (scope == _scope || (scope == EventsScope.myTeam && !hasTeam)) return Future.value();
    _scope = scope;
    return _reload();
  }

  Future<void> search(String text) {
    if (text == _text) return Future.value();
    _text = text;
    return _reload();
  }

  Future<void> selectStatus(EventStatus? status) {
    if (status == _status) return Future.value();
    _status = status;
    return _reload();
  }

  /// Anota los equipos del jugador, que dicen cuál es el activo. Si no se lo puede leer se sigue con el equipo que la app ya
  /// tenía (y, sin él, con todos los eventos): no se bloquea la pantalla por eso.
  Future<void> _syncActiveTeam() async {
    try {
      await _activeTeam.sync(await _playersService.getCurrent());
    } catch (_) {
      // Sin el jugador no se sabe más: se queda con lo que hay.
    }
    _watchedTeamId = _activeTeam.activeTeamId;
  }

  /// El jugador eligió ver otro de sus equipos: se vuelven a leer sus eventos. Los avisos que no cambian el equipo activo
  /// (la lista de equipos, por ejemplo) no recargan nada.
  void _onActiveTeamChanged() {
    final activeTeamId = _activeTeam.activeTeamId;
    final watchedTeamId = _watchedTeamId;
    if (watchedTeamId == null || activeTeamId == watchedTeamId) return;
    _watchedTeamId = activeTeamId;
    if (activeTeamId == null) _scope = EventsScope.all;
    if (_scope == EventsScope.myTeam || activeTeamId == null) _reload();
  }

  Future<void> _reload() async {
    final generation = ++_searchGeneration;
    _loading = true;
    _loadingMore = false;
    _error = null;
    _notify();
    try {
      final page = await _readFirstPage();
      if (generation != _searchGeneration) return;
      _events = page.events;
      _loadedPages = 1;
      _totalElements = page.totalElements;
      _hasMore = page.hasMore;
    } catch (_) {
      if (generation != _searchGeneration) return;
      _events = [];
      _hasMore = false;
      _error = _loadErrorKey;
    } finally {
      if (generation == _searchGeneration) {
        _loading = false;
        _notify();
      }
    }
  }

  /// La primera página de lo que se busca: los eventos del equipo activo, ya filtrados (caben en una sola página), o la
  /// primera que devuelve el backend.
  Future<EventsPage> _readFirstPage() async {
    final teamId = _scope == EventsScope.myTeam ? _activeTeam.activeTeamId : null;
    if (teamId == null) return _searchService.search(text: _text, status: _status);
    final teamEvents = _teamEventsById[teamId] ??= await _teamEventsService.getOfTeam(teamId);
    final events = filterEvents(teamEvents, text: _text, status: _status);
    return EventsPage(events: events, page: 0, totalPages: 1, totalElements: events.length);
  }

  /// Pide la página que sigue y la suma a las que ya hay. No hace nada si no quedan o si ya se está pidiendo una (los
  /// eventos de un equipo ya vienen enteros).
  Future<void> loadMore() async {
    if (!_hasMore || _loading || _loadingMore) return;
    final generation = _searchGeneration;
    _loadingMore = true;
    _notify();
    try {
      final page = await _searchService.search(text: _text, status: _status, page: _loadedPages);
      if (generation != _searchGeneration) return;
      _events = [..._events, ...page.events];
      _loadedPages += 1;
      _totalElements = page.totalElements;
      _hasMore = page.hasMore;
    } catch (_) {
      if (generation != _searchGeneration) return;
      _error = _loadErrorKey;
    } finally {
      if (generation == _searchGeneration) {
        _loadingMore = false;
        _notify();
      }
    }
  }

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
