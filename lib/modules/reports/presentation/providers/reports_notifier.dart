import 'package:flutter/foundation.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/shared/data/datasource/events_catalog_service.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/matches/data/datasource/matches_service.dart';
import 'package:sport_platform/modules/reports/domain/team_report.dart';

/// El estado del reporte del equipo del usuario, calculado con sus partidos.
class ReportsNotifier extends ChangeNotifier {
  /// Cuántos de los últimos resultados forman la «racha» que se muestra.
  static const recentFormLength = 5;

  final PlayersService _playersService;
  final MatchesService _matchesService;
  final EventsCatalogService _eventsService;

  ReportsNotifier({
    required PlayersService playersService,
    required MatchesService matchesService,
    required EventsCatalogService eventsService,
  }) : _playersService = playersService,
       _matchesService = matchesService,
       _eventsService = eventsService;

  bool _loading = true;
  String? _error;
  String? _teamId;
  String? _teamName;
  TeamRecord _record = const TeamRecord();
  List<MatchResult> _recentForm = [];
  List<({String eventName, TeamRecord record})> _byEvent = [];

  bool get loading => _loading;

  /// Clave de traducción del error (no el texto): sigue al idioma activo.
  String? get error => _error;

  /// El usuario no tiene equipo: no hay reporte que armar.
  bool get hasTeam => _teamId != null;
  String? get teamName => _teamName;
  TeamRecord get record => _record;
  List<MatchResult> get recentForm => List.unmodifiable(_recentForm);
  List<({String eventName, TeamRecord record})> get byEvent =>
      List.unmodifiable(_byEvent);

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final player = await _playersService.getCurrent();
      _teamId = player?.teamId;
      _teamName = player?.teamName;
      final teamId = _teamId;
      if (teamId == null) {
        _record = const TeamRecord();
        _recentForm = [];
        _byEvent = [];
      } else {
        await _buildReport(teamId);
      }
    } catch (_) {
      _error = 'reports.load_error';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _buildReport(String teamId) async {
    final results = await Future.wait<dynamic>([
      _matchesService.getMine(),
      _eventsService.getAll(),
    ]);
    final matches = results[0] as List<MatchModel>;
    final eventNames = {
      for (final event in results[1] as List<EventModel>) event.id: event.name,
    };
    _record = buildTeamRecord(teamId, matches);
    _recentForm = buildRecentForm(teamId, matches, limit: recentFormLength);
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
}
