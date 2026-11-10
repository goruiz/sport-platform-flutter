import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/services/user_session.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/teams_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/team_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/enums/match_status.dart';
import 'package:sport_platform/modules/events/shared/data/datasource/events_search_service.dart';
import 'package:sport_platform/modules/events/shared/data/datasource/team_events_service.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/event_status.dart';
import 'package:sport_platform/modules/matches/data/datasource/matches_service.dart';
import 'package:sport_platform/modules/matches/domain/match_rules.dart';
import 'package:sport_platform/modules/teams/presentation/providers/active_team_notifier.dart';

/// Lo que muestra el inicio: los eventos y los partidos del equipo activo del usuario.
class HomeDashboardData {
  /// Los eventos en que juega el equipo activo; quien aún no tiene equipo ve los primeros que ordena el backend.
  final List<EventModel> events;

  /// Los partidos del equipo activo (vacío si aún no tiene equipo), no los de toda la plataforma ni los de sus otros equipos.
  final List<MatchModel> matches;
  final List<TeamModel> teams;

  /// El equipo cuya información se muestra: el que el jugador eligió ver; null si no tiene equipo.
  final String? activeTeamId;

  const HomeDashboardData({
    required this.events,
    required this.matches,
    required this.teams,
    this.activeTeamId,
  });

  TeamModel? get currentTeam {
    final teamId = activeTeamId;
    if (teamId == null) return null;
    for (final team in teams) {
      if (team.id == teamId) return team;
    }
    return null;
  }

  /// El próximo evento: el que empieza antes entre los que no se cancelaron ni terminaron. Con un equipo activo solo
  /// cuentan los eventos en que juega ese equipo (si no tiene ninguno, no hay próximo evento: nunca se muestra uno de otro
  /// equipo); sin equipo, el que empieza antes de todos, y si el jugador tiene partidos, uno de sus eventos va primero.
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
    if (_hasActiveTeam) return null;
    return upcoming.isEmpty ? null : upcoming.first;
  }

  bool get _hasActiveTeam => activeTeamId != null && activeTeamId!.isNotEmpty;

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
  final TeamEventsService _teamEventsService = getIt<TeamEventsService>();
  final ActiveTeamNotifier _activeTeam = getIt<ActiveTeamNotifier>();

  Future<HomeDashboardData> load() async {
    await UserSession.loadFromStorage();
    // Solo lo que el inicio muestra: los partidos y el jugador del usuario, y de ahí su equipo y sus eventos; no todos los
    // eventos ni todos los equipos que la app puede ver.
    final responses = await Future.wait<dynamic>([
      _matchesService.getMine(),
      _playersService.getCurrent(),
    ]);
    final allMatches = responses[0] as List<MatchModel>;
    final activeTeamId = (await _activeTeam.sync(responses[1] as PlayerModel?))?.teamId;
    final eventsAndTeam = await Future.wait<dynamic>([
      _readEvents(allMatches, activeTeamId),
      _readTeam(activeTeamId),
    ]);

    return HomeDashboardData(
      events: eventsAndTeam[0] as List<EventModel>,
      // `getMine` trae los partidos de todos sus equipos: el inicio muestra solo los del equipo activo.
      matches: matchesOfTeam(allMatches, activeTeamId),
      teams: eventsAndTeam[1] as List<TeamModel>,
      activeTeamId: activeTeamId,
    );
  }

  /// Los eventos en que juega el equipo activo (los de sus partidos, que ya se leyeron); sin equipo, la primera página
  /// que ordena el backend (lo que está en curso va primero).
  Future<List<EventModel>> _readEvents(List<MatchModel> allMatches, String? activeTeamId) async {
    if (activeTeamId == null || activeTeamId.isEmpty) return (await _eventsSearchService.search()).events;
    return _teamEventsService.getOfMatches(allMatches, activeTeamId);
  }

  Future<List<TeamModel>> _readTeam(String? teamId) async {
    if (teamId == null || teamId.isEmpty) return const [];
    final team = await _teamsService.getById(teamId);
    return team == null ? const [] : [team];
  }
}
