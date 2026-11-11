import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/team_event_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/repositories/i_league_matches_repository.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/repositories/i_league_teams_repository.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/pages/team_in_event_page.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/providers/league_detail_notifier.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/league_info_card.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/league_matches_tab.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/league_teams_tab.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/standings_tab.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/events/shared/presentation/widgets/championship_tab.dart';
import 'package:sport_platform/modules/events/shared/presentation/widgets/event_rules_card.dart';
import 'package:sport_platform/modules/matches/presentation/pages/match_detail_page.dart';

/// El detalle de un evento para el jugador: información, equipos, partidos y posiciones (o campeonato).
/// Solo se lee: el organizador lo gestiona desde el panel.
class LeagueDetailPage extends StatefulWidget {
  final EventModel event;

  const LeagueDetailPage({super.key, required this.event});

  @override
  State<LeagueDetailPage> createState() => _LeagueDetailPageState();
}

class _LeagueDetailPageState extends State<LeagueDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final LeagueDetailNotifier _notifier;

  EventModel get _event => widget.event;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _notifier = LeagueDetailNotifier(
      teamsRepo: getIt<ILeagueTeamsRepository>(),
      matchesRepo: getIt<ILeagueMatchesRepository>(),
      eventId: _event.id,
    );
    _notifier.loadTeams();
    _notifier.loadMatches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notifier.dispose();
    super.dispose();
  }

  /// El detalle de un equipo del evento: su balance, sus partidos, sus goleadores y, si se ve, su plantilla.
  void _openTeam(TeamEventModel team) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TeamInEventPage(
          event: _event,
          team: team,
          teamNames: {for (final t in _notifier.teams) t.teamId: t.teamName},
        ),
      ),
    );
  }

  /// El detalle del partido: su cronología de goles y tarjetas (la registra el organizador en el panel).
  void _openMatch(MatchModel match) {
    final teamNames = {for (final team in _notifier.teams) team.teamId: team.teamName};
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MatchDetailPage(
          match: match,
          homeName: teamNames[match.homeTeamId] ?? '—',
          awayName: teamNames[match.awayTeamId] ?? '—',
          eventName: _event.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _notifier,
      builder: (context, _) => Scaffold(
        appBar: _buildAppBar(),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildInfoTab(),
            _buildTeamsTab(),
            _buildMatchesTab(),
            _buildStandingsTab(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_event.name),
      bottom: TabBar(
        controller: _tabController,
        // Con cuatro pestañas en un teléfono los nombres no caben fijos y se cortaban («Informaci…»).
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: [
          Tab(text: 'leagues.detail_tab_info'.tr()),
          Tab(text: 'leagues.detail_tab_teams'.tr()),
          Tab(text: 'leagues.detail_tab_matches'.tr()),
          Tab(
            text: _event.hasChampionship
                ? 'championship.tab_title'.tr()
                : 'leagues.detail_tab_standings'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          LeagueInfoCard(event: _event),
          const SizedBox(height: 16),
          EventRulesCard(event: _event),
        ],
      ),
    );
  }

  Widget _buildTeamsTab() {
    return LeagueTeamsTab(
      teams: _notifier.teams,
      isLoading: _notifier.loadingTeams,
      error: _notifier.teamsError?.tr(),
      onRetry: _notifier.loadTeams,
      onOpen: _openTeam,
    );
  }

  Widget _buildMatchesTab() {
    return LeagueMatchesTab(
      groupedMatches: _notifier.groupedMatches,
      teamMap: {for (final t in _notifier.teams) t.teamId: t.teamName},
      isLoading: _notifier.loadingMatches,
      error: _notifier.matchesError?.tr(),
      onRetry: _notifier.loadMatches,
      onOpen: _openMatch,
    );
  }

  /// Un evento con formato muestra su campeonato (etapas, tablas y llave); uno sin formato, la
  /// tabla de posiciones de siempre.
  Widget _buildStandingsTab() {
    if (_notifier.loadingTeams || _notifier.loadingMatches) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryLight),
      );
    }
    if (_event.hasChampionship) {
      return ChampionshipTab(eventId: _event.id);
    }
    return StandingsTab(eventId: _event.id);
  }
}
