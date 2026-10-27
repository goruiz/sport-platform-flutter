import 'package:flutter/foundation.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/courts_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/teams_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/court_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/team_model.dart';
import 'package:sport_platform/modules/events/shared/data/datasource/events_catalog_service.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/matches/data/datasource/matches_service.dart';

/// De qué partidos se habla: los del equipo del usuario o todos los de la plataforma.
enum MatchesScope { mine, all }

/// El estado de la pantalla Partidos. Abre con los partidos del equipo del usuario (son pocos) y
/// solo descarga todos los de la plataforma cuando el usuario lo pide.
class MatchesNotifier extends ChangeNotifier {
  final MatchesService _matchesService;
  final EventsCatalogService _eventsService;
  final TeamsService _teamsService;
  final CourtsService _courtsService;

  MatchesNotifier({
    required MatchesService matchesService,
    required EventsCatalogService eventsService,
    required TeamsService teamsService,
    required CourtsService courtsService,
  })  : _matchesService = matchesService,
        _eventsService = eventsService,
        _teamsService = teamsService,
        _courtsService = courtsService;

  MatchesScope _scope = MatchesScope.mine;
  List<MatchModel> _mine = [];
  List<MatchModel> _all = [];
  bool _allLoaded = false;
  bool _loading = true;
  bool _loadingAll = false;
  String? _error;

  Map<String, String> _teamNames = {};
  Map<String, String> _eventNames = {};
  Map<String, CourtModel> _courtsById = {};

  MatchesScope get scope => _scope;
  bool get loading => _loading;
  bool get loadingAll => _loadingAll;

  /// Clave de traducción del error (no el texto): sigue al idioma activo.
  String? get error => _error;

  /// El usuario no tiene equipo (o su equipo aún no juega): «Mi equipo» queda vacío.
  bool get hasNoMatchesOfMyTeam => _mine.isEmpty;

  List<MatchModel> get visibleMatches =>
      List.unmodifiable(_scope == MatchesScope.mine ? _mine : _all);

  Future<void> load() async {
    _loading = true;
    _error = null;
    _allLoaded = false;
    notifyListeners();
    try {
      final results = await Future.wait<dynamic>([
        _matchesService.getMine(),
        _eventsService.getAll(),
        _teamsService.getAll(),
        _courtsService.getAll(),
      ]);
      _mine = results[0] as List<MatchModel>;
      _eventNames = {for (final event in results[1] as List<EventModel>) event.id: event.name};
      _teamNames = {for (final team in results[2] as List<TeamModel>) team.id: team.name};
      _courtsById = {for (final court in results[3] as List<CourtModel>) court.id: court};
      // Sin partidos propios no hay nada que mostrar en «Mi equipo»: se abre con todos.
      _scope = _mine.isEmpty ? MatchesScope.all : MatchesScope.mine;
    } catch (_) {
      _error = 'mobile.matches.load_error';
    } finally {
      _loading = false;
      notifyListeners();
    }
    if (_error == null && _scope == MatchesScope.all) await _loadAll();
  }

  Future<void> selectScope(MatchesScope scope) async {
    if (scope == _scope) return;
    _scope = scope;
    notifyListeners();
    if (scope == MatchesScope.all) await _loadAll();
  }

  Future<void> _loadAll() async {
    if (_allLoaded) return;
    _loadingAll = true;
    _error = null;
    notifyListeners();
    try {
      _all = await _matchesService.getAll();
      _allLoaded = true;
    } catch (_) {
      _error = 'mobile.matches.load_error';
    } finally {
      _loadingAll = false;
      notifyListeners();
    }
  }

  String teamName(String teamId) => _teamNames[teamId] ?? '—';

  String eventName(String eventId) => _eventNames[eventId] ?? '';

  String? courtName(String? courtId) =>
      courtId == null ? null : _courtsById[courtId]?.displayName;
}
