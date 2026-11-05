import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/services/user_session.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/teams_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/team_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/enums/match_status.dart';
import 'package:sport_platform/modules/events/shared/data/datasource/events_search_service.dart';
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

  /// El nombre de un equipo: el del propio equipo del usuario o el que el backend puso en sus partidos; un guion si
  /// el jugador no ve ese equipo.
  String teamName(String teamId) {
    for (final team in teams) {
      if (team.id == teamId) return team.name;
    }
    for (final match in matches) {
      if (match.homeTeamId == teamId && match.homeTeamName != null) return match.homeTeamName!;
      if (match.awayTeamId == teamId && match.awayTeamName != null) return match.awayTeamName!;
    }
    return '—';
  }

  String eventName(String eventId) {
    for (final event in events) {
      if (event.id == eventId) return event.name;
    }
    for (final match in matches) {
      if (match.eventId == eventId && match.eventName != null) return match.eventName!;
    }
    return '';
  }
}

class HomeDashboardService {
  final EventsSearchService _eventsSearchService = getIt<EventsSearchService>();
  final MatchesService _matchesService = getIt<MatchesService>();
  final TeamsService _teamsService = getIt<TeamsService>();
  final PlayersService _playersService = getIt<PlayersService>();

  Future<HomeDashboardData> load() async {
    await UserSession.loadFromStorage();
    // Solo lo que el inicio muestra: la primera página de eventos (lo que está en curso va primero), los partidos y el
    // jugador del usuario y su equipo; no todos los eventos ni todos los equipos que la app puede ver.
    final responses = await Future.wait<dynamic>([
      _eventsSearchService.search(),
      _matchesService.getMine(),
      _playersService.getCurrent(),
    ]);
    final player = responses[2] as PlayerModel?;

    return HomeDashboardData(
      events: (responses[0] as EventsPage).events,
      matches: responses[1] as List<MatchModel>,
      teams: await _readTeamOf(player),
      currentPlayer: player,
    );
  }

  Future<List<TeamModel>> _readTeamOf(PlayerModel? player) async {
    final teamId = player?.teamId;
    if (teamId == null || teamId.isEmpty) return const [];
    final team = await _teamsService.getById(teamId);
    return team == null ? const [] : [team];
  }
}
