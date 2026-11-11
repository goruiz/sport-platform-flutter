import 'package:flutter/material.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/repositories/i_league_matches_repository.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/repositories/i_league_teams_repository.dart';
import '../../data/models/match_model.dart';
import '../../data/models/team_event_model.dart';

/// Los equipos y los partidos de un evento, solo para leerlos: los gestiona el organizador desde el panel.
class LeagueDetailNotifier extends ChangeNotifier {
  final ILeagueTeamsRepository _teamsRepo;
  final ILeagueMatchesRepository _matchesRepo;
  final String eventId;

  List<TeamEventModel> _teams = [];
  List<(DateTime, List<MatchModel>)> _groupedMatches = [];
  bool _loadingTeams = true;
  bool _loadingMatches = true;
  String? _teamsError;
  String? _matchesError;

  LeagueDetailNotifier({
    required ILeagueTeamsRepository teamsRepo,
    required ILeagueMatchesRepository matchesRepo,
    required this.eventId,
  })  : _teamsRepo = teamsRepo,
        _matchesRepo = matchesRepo;

  List<TeamEventModel> get teams => List.unmodifiable(_teams);
  List<(DateTime, List<MatchModel>)> get groupedMatches =>
      List.unmodifiable(_groupedMatches);
  bool get loadingTeams => _loadingTeams;
  bool get loadingMatches => _loadingMatches;
  String? get teamsError => _teamsError;
  String? get matchesError => _matchesError;

  Future<void> loadTeams() async {
    _loadingTeams = true;
    _teamsError = null;
    notifyListeners();
    try {
      _teams = await _teamsRepo.getByEvent(eventId);
    } catch (_) {
      _teamsError = 'leagues.error_load_teams';
    } finally {
      _loadingTeams = false;
      notifyListeners();
    }
  }

  Future<void> loadMatches() async {
    _loadingMatches = true;
    _matchesError = null;
    notifyListeners();
    try {
      _groupedMatches = _groupByDate(await _matchesRepo.getByEvent(eventId));
    } catch (_) {
      _matchesError = 'leagues.error_load_matches';
    } finally {
      _loadingMatches = false;
      notifyListeners();
    }
  }

  static List<(DateTime, List<MatchModel>)> _groupByDate(
      List<MatchModel> matches) {
    final sorted = [...matches]
      ..sort((a, b) => a.matchDate.compareTo(b.matchDate));
    final keys = <String>[];
    final groups = <String, List<MatchModel>>{};
    for (final m in sorted) {
      final key =
          '${m.matchDate.year}-${m.matchDate.month.toString().padLeft(2, '0')}-${m.matchDate.day.toString().padLeft(2, '0')}';
      if (!groups.containsKey(key)) keys.add(key);
      groups.putIfAbsent(key, () => []).add(m);
    }
    return keys.map((k) => (groups[k]!.first.matchDate, groups[k]!)).toList();
  }
}
