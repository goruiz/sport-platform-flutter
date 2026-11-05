import 'package:flutter/foundation.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/courts_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/court_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/shared/data/datasource/events_search_service.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/matches/data/datasource/matches_service.dart';

/// De qué partidos se habla: los del equipo del usuario o los de un evento que elige.
enum MatchesScope { mine, all }

/// El estado de la pantalla Partidos. Abre con los partidos del equipo del usuario (son pocos) y, cuando pide «todos»,
/// lee los de **un evento a la vez** (el que elige entre los primeros que le muestra el backend): así nunca se descarga
/// todo lo de la plataforma, que crece con los eventos públicos de cada organización.
class MatchesNotifier extends ChangeNotifier {
  final MatchesService _matchesService;
  final EventsSearchService _eventsSearchService;
  final CourtsService _courtsService;

  MatchesNotifier({
    required MatchesService matchesService,
    required EventsSearchService eventsSearchService,
    required CourtsService courtsService,
  })  : _matchesService = matchesService,
        _eventsSearchService = eventsSearchService,
        _courtsService = courtsService;

  MatchesScope _scope = MatchesScope.mine;
  List<MatchModel> _mine = [];
  List<EventModel> _eventOptions = [];
  bool _eventOptionsLoaded = false;
  String? _selectedEventId;
  final Map<String, List<MatchModel>> _matchesByEventId = {};
  bool _loading = true;
  bool _loadingAll = false;
  String? _error;

  Map<String, CourtModel> _courtsById = {};

  MatchesScope get scope => _scope;
  bool get loading => _loading;
  bool get loadingAll => _loadingAll;

  /// Clave de traducción del error (no el texto): sigue al idioma activo.
  String? get error => _error;

  /// El usuario no tiene equipo (o su equipo aún no juega): «Mi equipo» queda vacío.
  bool get hasNoMatchesOfMyTeam => _mine.isEmpty;

  /// Los eventos entre los que elige en «Todos» (los primeros que ordena el backend: lo que está en curso va primero).
  List<EventModel> get eventOptions => List.unmodifiable(_eventOptions);
  String? get selectedEventId => _selectedEventId;

  List<MatchModel> get visibleMatches {
    if (_scope == MatchesScope.mine) return List.unmodifiable(_mine);
    return List.unmodifiable(_matchesByEventId[_selectedEventId] ?? const <MatchModel>[]);
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    _eventOptionsLoaded = false;
    _matchesByEventId.clear();
    notifyListeners();
    try {
      final results = await Future.wait<dynamic>([
        _matchesService.getMine(),
        _courtsService.getAll(),
      ]);
      _mine = results[0] as List<MatchModel>;
      _courtsById = {for (final court in results[1] as List<CourtModel>) court.id: court};
      // Sin partidos propios no hay nada que mostrar en «Mi equipo»: se abre con los eventos.
      _scope = _mine.isEmpty ? MatchesScope.all : MatchesScope.mine;
    } catch (_) {
      _error = 'mobile.matches.load_error';
    } finally {
      _loading = false;
      notifyListeners();
    }
    if (_error == null && _scope == MatchesScope.all) await _loadSelectedEvent();
  }

  Future<void> selectScope(MatchesScope scope) async {
    if (scope == _scope) return;
    _scope = scope;
    notifyListeners();
    if (scope == MatchesScope.all) await _loadSelectedEvent();
  }

  Future<void> selectEvent(String eventId) async {
    if (eventId == _selectedEventId) return;
    _selectedEventId = eventId;
    notifyListeners();
    await _loadSelectedEvent();
  }

  /// Lee los eventos que se ofrecen (una sola vez) y los partidos del que está elegido (una vez por evento).
  Future<void> _loadSelectedEvent() async {
    _loadingAll = true;
    _error = null;
    notifyListeners();
    try {
      if (!_eventOptionsLoaded) {
        _eventOptions = (await _eventsSearchService.search()).events;
        _eventOptionsLoaded = true;
      }
      _selectedEventId ??= _eventOptions.isEmpty ? null : _eventOptions.first.id;
      final eventId = _selectedEventId;
      if (eventId != null && !_matchesByEventId.containsKey(eventId)) {
        _matchesByEventId[eventId] = await _matchesService.getByEvent(eventId);
      }
    } catch (_) {
      _error = 'mobile.matches.load_error';
    } finally {
      _loadingAll = false;
      notifyListeners();
    }
  }

  /// Los nombres vienen en el propio partido (el backend los pone al leerlo); un equipo que el jugador no ve no tiene.
  String homeName(MatchModel match) => match.homeTeamName ?? '—';

  String awayName(MatchModel match) => match.awayTeamName ?? '—';

  String eventNameOf(MatchModel match) => match.eventName ?? '';

  String? courtName(String? courtId) =>
      courtId == null ? null : _courtsById[courtId]?.displayName;
}
