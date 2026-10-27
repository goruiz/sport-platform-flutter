import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/services/user_session.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/teams_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/team_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/enums/match_status.dart';
import 'package:sport_platform/modules/events/shared/data/datasource/events_catalog_service.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/event_status.dart';
import 'package:sport_platform/modules/matches/data/datasource/matches_service.dart';
import 'package:sport_platform/modules/matches/domain/match_rules.dart';

/// Lo que muestra el inicio: los eventos, los partidos del equipo del usuario y su jugador.
class HomeDashboardData {
  final List<EventModel> events;

  /// Los partidos del equipo del usuario (vacío si aún no tiene equipo), no los de toda la plataforma.
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

  /// El próximo evento. Si el equipo del usuario juega en alguno, de esos el que empieza antes; si
  /// no, el que empieza antes de todos. Los cancelados y los que ya terminaron no cuentan.
  EventModel? nextEvent([DateTime? now]) {
    final clock = now ?? DateTime.now();
    final today = DateTime(clock.year, clock.month, clock.day);
    final upcoming = events.where((event) {
      final endDate = DateTime(event.endDate.year, event.endDate.month, event.endDate.day);
      return event.statusType != EventStatus.cancelled && !endDate.isBefore(today);
    }).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final myEventIds = matches.map((match) => match.eventId).toSet();
    for (final event in upcoming) {
      if (myEventIds.contains(event.id)) return event;
    }
    return upcoming.isEmpty ? null : upcoming.first;
  }

  /// El próximo partido del equipo del usuario.
  MatchModel? nextMatch([DateTime? now]) {
    final upcoming = upcomingMatches(matches, now ?? DateTime.now());
    return upcoming.isEmpty ? null : upcoming.first;
  }

  /// El último resultado del equipo del usuario.
  MatchModel? latestResult([DateTime? now]) {
    final clock = now ?? DateTime.now();
    final played = playedMatches(matches)
        .where((match) => match.matchDate.isBefore(clock) && match.status != MatchStatus.cancelled)
        .toList();
    return played.isEmpty ? null : played.first;
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
  final EventsCatalogService _eventsService = getIt<EventsCatalogService>();
  final MatchesService _matchesService = getIt<MatchesService>();
  final TeamsService _teamsService = getIt<TeamsService>();
  final PlayersService _playersService = getIt<PlayersService>();

  Future<HomeDashboardData> load() async {
    await UserSession.loadFromStorage();
    final responses = await Future.wait<dynamic>([
      _eventsService.getAll(),
      _matchesService.getMine(),
      _teamsService.getAll(),
      _playersService.getCurrent(),
    ]);

    return HomeDashboardData(
      events: responses[0] as List<EventModel>,
      matches: responses[1] as List<MatchModel>,
      teams: responses[2] as List<TeamModel>,
      currentPlayer: responses[3] as PlayerModel?,
    );
  }
}
