import 'package:dio/dio.dart';
import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/network/response_parser.dart';
import 'package:sport_platform/core/services/user_session.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/teams_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/team_model.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';

class HomeDashboardData {
  final List<EventModel> events;
  final List<MatchModel> matches;
  final List<TeamModel> teams;
  final PlayerModel? currentPlayer;

  const HomeDashboardData({
    required this.events,
    required this.matches,
    required this.teams,
    required this.currentPlayer,
  });

  TeamModel? get currentTeam {
    final teamId = currentPlayer?.teamId;
    if (teamId == null) return null;
    for (final team in teams) {
      if (team.id == teamId) return team;
    }
    return null;
  }

  EventModel? get nextEvent {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = events.where((event) {
      final endDate = DateTime(
        event.endDate.year,
        event.endDate.month,
        event.endDate.day,
      );
      return event.status.toUpperCase() != 'CANCELLED' &&
          !endDate.isBefore(today);
    }).toList()..sort((a, b) => a.startDate.compareTo(b.startDate));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  MatchModel? get nextMatch {
    final now = DateTime.now();
    final upcoming =
        matches
            .where(
              (match) =>
                  match.matchDate.isAfter(now) &&
                  match.status.toJson() != 'CANCELLED',
            )
            .toList()
          ..sort((a, b) => a.matchDate.compareTo(b.matchDate));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  MatchModel? get latestResult {
    final completed =
        matches
            .where(
              (match) =>
                  match.homeScore != null &&
                  match.awayScore != null &&
                  match.matchDate.isBefore(DateTime.now()),
            )
            .toList()
          ..sort((a, b) => b.matchDate.compareTo(a.matchDate));
    return completed.isEmpty ? null : completed.first;
  }

  String teamName(String teamId) {
    for (final team in teams) {
      if (team.id == teamId) return team.name;
    }
    return '—';
  }

  String eventName(String eventId) {
    for (final event in events) {
      if (event.id == eventId) return event.name;
    }
    return '';
  }
}

class HomeDashboardService {
  final DioClient _client = DioClient();
  final TeamsService _teamsService = TeamsService();
  final PlayersService _playersService = PlayersService();

  Future<HomeDashboardData> load() async {
    await UserSession.loadFromStorage();
    final responses = await Future.wait<dynamic>([
      _client.get(ApiEndpoints.events),
      _client.get(ApiEndpoints.matches),
      _teamsService.getAll(),
      _loadCurrentPlayer(),
    ]);

    return HomeDashboardData(
      events: ResponseParser.toList(responses[0].data)
          .map((item) => EventModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      matches: ResponseParser.toList(responses[1].data)
          .map((item) => MatchModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      teams: responses[2] as List<TeamModel>,
      currentPlayer: responses[3] as PlayerModel?,
    );
  }

  Future<PlayerModel?> _loadCurrentPlayer() async {
    final email = UserSession.current?.email;
    if (email == null || email.isEmpty) return null;
    try {
      return await _playersService.searchByEmail(email);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
