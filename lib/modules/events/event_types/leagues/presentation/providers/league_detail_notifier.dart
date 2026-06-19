import 'package:flutter/material.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/repositories/i_league_matches_repository.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/repositories/i_league_teams_repository.dart';
import '../../data/models/match_model.dart';
import '../../data/models/team_event_model.dart';

class LeagueDetailNotifier extends ChangeNotifier {
  final ILeagueTeamsRepository _teamsRepo;
  final ILeagueMatchesRepository _matchesRepo;
  final String eventId;

  List<TeamEventModel> _teams = [];
  List<MatchModel> _matches = [];
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
  List<MatchModel> get matches => List.unmodifiable(_matches);
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
      final result = await _matchesRepo.getByEvent(eventId);
      _matches = result;
      _groupedMatches = _groupByDate(result);
    } catch (_) {
      _matchesError = 'leagues.error_load_matches';
    } finally {
      _loadingMatches = false;
      notifyListeners();
    }
  }

  Future<TeamEventModel> addTeam(String teamId) async {
    final added = await _teamsRepo.add(teamId, eventId);
    _teams = [..._teams, added];
    notifyListeners();
    return added;
  }

  Future<void> removeTeam(String teamsEventsId) async {
    await _teamsRepo.remove(teamsEventsId);
    _teams = _teams.where((t) => t.id != teamsEventsId).toList();
    notifyListeners();
  }

  Future<MatchModel> createMatch(Map<String, dynamic> data) async {
    final created = await _matchesRepo.create(data);
    _matches = [created, ..._matches];
    _groupedMatches = _groupByDate(_matches);
    notifyListeners();
    return created;
  }

  Future<MatchModel> updateMatch(String id, Map<String, dynamic> data) async {
    final updated = await _matchesRepo.update(id, data);
    _replaceMatch(updated);
    notifyListeners();
    return updated;
  }

  Future<void> deleteMatch(String id) async {
    await _matchesRepo.delete(id);
    _matches = _matches.where((m) => m.id != id).toList();
    _groupedMatches = _groupByDate(_matches);
    notifyListeners();
  }

  void addGeneratedMatches(List<MatchModel> generated) {
    _matches = [..._matches, ...generated];
    _groupedMatches = _groupByDate(_matches);
    notifyListeners();
  }

  Future<MatchModel> postponeMatch(String id) async {
    final updated = await _matchesRepo.postpone(id);
    _replaceMatch(updated);
    notifyListeners();
    return updated;
  }

  Future<MatchModel> suspendMatch(String id) async {
    final updated = await _matchesRepo.suspend(id);
    _replaceMatch(updated);
    notifyListeners();
    return updated;
  }

  Future<MatchModel> rescheduleMatch(String id, DateTime newDate) async {
    final updated = await _matchesRepo.reschedule(id, newDate);
    _replaceMatch(updated);
    notifyListeners();
    return updated;
  }

  void _replaceMatch(MatchModel updated) {
    final copy = [..._matches];
    final idx = copy.indexWhere((m) => m.id == updated.id);
    if (idx != -1) copy[idx] = updated;
    _matches = copy;
    _groupedMatches = _groupByDate(_matches);
  }

  Future<List<MatchModel>> rescheduleDateMatches(
    DateTime fromDate, {
    DateTime? toDate,
  }) async {
    final updated =
        await _matchesRepo.rescheduleDate(eventId, fromDate, toDate: toDate);
    final copy = [..._matches];
    for (final u in updated) {
      final idx = copy.indexWhere((m) => m.id == u.id);
      if (idx != -1) copy[idx] = u;
    }
    _matches = copy;
    _groupedMatches = _groupByDate(_matches);
    notifyListeners();
    return updated;
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
