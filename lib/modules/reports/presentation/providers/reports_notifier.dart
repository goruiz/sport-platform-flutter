import 'package:flutter/foundation.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/matches/data/datasource/matches_service.dart';
import 'package:sport_platform/modules/matches/domain/match_rules.dart';
import 'package:sport_platform/modules/rankings/data/datasource/player_stats_service.dart';
import 'package:sport_platform/modules/reports/domain/team_report.dart';
import 'package:sport_platform/modules/teams/presentation/providers/active_team_notifier.dart';
import 'package:sport_platform/shared/enums/summary_status.dart';

/// El estado del reporte del equipo activo del usuario, calculado con sus partidos. Quien juega en varios equipos (uno
/// por organización) ve el reporte del que tiene elegido en la app ([ActiveTeamNotifier]) y se vuelve a armar al cambiarlo.
///
/// El balance, la racha y los eventos salen de los partidos del equipo. Las tarjetas y faltas necesitan una lectura más
/// por evento (`/events/{id}/player-stats`), así que van aparte: la pantalla ya se puede mostrar mientras llegan, y si
/// fallan solo ese bloque lo dice.
class ReportsNotifier extends ChangeNotifier {
  /// Cuántos de los últimos resultados forman la «racha» que se muestra.
  static const recentFormLength = 5;

  final PlayersService _playersService;
  final MatchesService _matchesService;
  final PlayerStatsService _playerStatsService;
  final ActiveTeamNotifier _activeTeam;

  ReportsNotifier({
    required PlayersService playersService,
    required MatchesService matchesService,
    required PlayerStatsService playerStatsService,
    required ActiveTeamNotifier activeTeam,
  }) : _playersService = playersService,
       _matchesService = matchesService,
       _playerStatsService = playerStatsService,
       _activeTeam = activeTeam {
    _activeTeam.addListener(_onActiveTeamChanged);
  }

  bool _loading = true;
  String? _error;

  /// El equipo activo cuya lectura está en curso o terminó por última vez: lo que se compara para saber si cambió.
  String? _watchedTeamId;
  String? _teamId;
  String? _teamName;
  TeamRecord _record = const TeamRecord();
  List<MatchResult> _recentForm = [];
  List<({String eventName, TeamRecord record})> _byEvent = [];
  int _eventsPlayed = 0;
  Set<String> _eventIds = const {};
  SummaryStatus _disciplineStatus = SummaryStatus.loading;
  TeamDiscipline _discipline = const TeamDiscipline();

  /// Cuenta las lecturas: la respuesta de una que ya no es la última (el usuario refrescó) se descarta.
  int _loadCount = 0;
  bool _isDisposed = false;

  bool get loading => _loading;

  /// Clave de traducción del error (no el texto): sigue al idioma activo.
  String? get error => _error;

  /// El usuario no tiene equipo: no hay reporte que armar.
  bool get hasTeam => _teamId != null;
  String? get teamName => _teamName;

  /// El equipo del que es el reporte.
  String? get selectedTeamId => _teamId;
  TeamRecord get record => _record;
  List<MatchResult> get recentForm => List.unmodifiable(_recentForm);
  List<({String eventName, TeamRecord record})> get byEvent =>
      List.unmodifiable(_byEvent);

  /// En cuántos eventos tiene partidos el equipo.
  int get eventsPlayed => _eventsPlayed;

  /// Cómo va la lectura de las tarjetas y faltas del equipo.
  SummaryStatus get disciplineStatus => _disciplineStatus;
  TeamDiscipline get discipline => _discipline;

  Future<void> load() async {
    final loadId = ++_loadCount;
    _loading = true;
    _error = null;
    _disciplineStatus = SummaryStatus.loading;
    _notify();
    try {
      final player = await _playersService.getCurrent();
      if (loadId != _loadCount) return;
      final chosen = await _activeTeam.sync(player);
      if (loadId != _loadCount) return;
      _watchedTeamId = chosen?.teamId;
      _teamId = chosen?.teamId;
      _teamName = chosen?.teamName;
      final teamId = _teamId;
      if (teamId == null) {
        _clearReport();
      } else {
        await _buildReport(teamId);
      }
    } catch (_) {
      if (loadId != _loadCount) return;
      _error = 'reports.load_error';
    }
    if (loadId != _loadCount) return;
    _loading = false;
    _notify();
    if (_error == null && hasTeam) await _loadDiscipline(loadId);
  }

  /// El jugador eligió ver otro de sus equipos: se arma el reporte de ese. Los avisos que no cambian el equipo activo (la
  /// lista de equipos, por ejemplo) no recargan nada.
  void _onActiveTeamChanged() {
    final activeTeamId = _activeTeam.activeTeamId;
    final watchedTeamId = _watchedTeamId;
    if (watchedTeamId == null || activeTeamId == watchedTeamId) return;
    _watchedTeamId = activeTeamId;
    load();
  }

  void _clearReport() {
    _record = const TeamRecord();
    _recentForm = [];
    _byEvent = [];
    _eventsPlayed = 0;
    _eventIds = const {};
    _discipline = const TeamDiscipline();
  }

  Future<void> _buildReport(String teamId) async {
    // `getMine` trae los partidos de todos sus equipos: el reporte cuenta solo los del equipo activo.
    final matches = matchesOfTeam(await _matchesService.getMine(), teamId);
    // El nombre del evento viene en cada partido: no hace falta bajar todos los eventos solo para rotular el reporte.
    final eventNames = <String, String>{
      for (final match in matches)
        if (match.eventName != null) match.eventId: match.eventName!,
    };
    _record = buildTeamRecord(teamId, matches);
    _recentForm = buildRecentForm(teamId, matches, limit: recentFormLength);
    _eventsPlayed = countEventsPlayed(matches);
    _eventIds = _eventIdsOf(matches);
    _byEvent =
        buildRecordsByEvent(teamId, matches).entries
            .map(
              (entry) => (
                eventName: eventNames[entry.key] ?? '—',
                record: entry.value,
              ),
            )
            .toList()
          ..sort((a, b) => b.record.played.compareTo(a.record.played));
  }

  Set<String> _eventIdsOf(Iterable<MatchModel> matches) => {
    for (final match in matches)
      if (match.eventId.isNotEmpty) match.eventId,
  };

  /// Las tarjetas y faltas del equipo: lo de sus jugadores en cada evento donde juega.
  Future<void> _loadDiscipline(int loadId) async {
    final teamId = _teamId;
    if (teamId == null) return;
    TeamDiscipline discipline = const TeamDiscipline();
    var status = SummaryStatus.ready;
    try {
      final statsByEvent = await Future.wait(
        _eventIds.map(_playerStatsService.getByEvent),
      );
      discipline = buildTeamDiscipline(teamId, statsByEvent);
    } catch (_) {
      status = SummaryStatus.failed;
    }
    if (loadId != _loadCount) return;
    _discipline = discipline;
    _disciplineStatus = status;
    _notify();
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
