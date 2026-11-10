import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/app_constants.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/team_event_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/team_in_event.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/providers/team_in_event_notifier.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/team_in_event_sections.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/matches/presentation/pages/match_detail_page.dart';
import 'package:sport_platform/modules/matches/presentation/widgets/match_summary_card.dart';
import 'package:sport_platform/modules/rankings/domain/leaderboards.dart';
import 'package:sport_platform/modules/reports/domain/team_report.dart';
import 'package:sport_platform/modules/reports/presentation/widgets/recent_form_chips.dart';
import 'package:sport_platform/modules/reports/presentation/widgets/team_record_card.dart';
import 'package:sport_platform/modules/reports/presentation/widgets/team_stats_card.dart';
import 'package:sport_platform/modules/teams/domain/team_members.dart';
import 'package:sport_platform/shared/enums/summary_status.dart';
import 'package:sport_platform/shared/widgets/app_card.dart';
import 'package:sport_platform/shared/widgets/initials_avatar.dart';
import 'package:sport_platform/shared/widgets/skeleton_box.dart';

/// Un equipo dentro de un evento, para conocer a un rival: su balance y su racha, sus próximos partidos y últimos
/// resultados, sus goleadores, sus tarjetas y, si el backend lo deja ver, su plantilla. Todo es de lectura.
class TeamInEventPage extends StatefulWidget {
  final EventModel event;
  final TeamEventModel team;

  /// Los nombres de los equipos del evento por id, para rotular un partido cuyo nombre no vino.
  final Map<String, String> teamNames;

  const TeamInEventPage({
    super.key,
    required this.event,
    required this.team,
    this.teamNames = const {},
  });

  @override
  State<TeamInEventPage> createState() => _TeamInEventPageState();
}

class _TeamInEventPageState extends State<TeamInEventPage> {
  static const Widget _gap = SizedBox(height: AppSpacing.section);

  late final TeamInEventNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = TeamInEventNotifier(
      matchesService: getIt(),
      playerStatsService: getIt(),
      playersService: getIt(),
      eventId: widget.event.id,
      teamId: widget.team.teamId,
    )..load();
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  String _nameOf(String teamId, String? backendName) =>
      backendName ?? widget.teamNames[teamId] ?? '—';

  void _openMatch(MatchModel match) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MatchDetailPage(
          match: match,
          homeName: _nameOf(match.homeTeamId, match.homeTeamName),
          awayName: _nameOf(match.awayTeamId, match.awayTeamName),
          eventName: widget.event.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Scaffold(
      backgroundColor: AppColors.backgroundEnd,
      appBar: AppBar(title: Text(widget.team.teamName)),
      body: ListenableBuilder(
        listenable: _notifier,
        builder: (context, _) => RefreshIndicator(
          onRefresh: _notifier.load,
          color: AppColors.primaryLight,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.lg,
              AppSpacing.page,
              AppSpacing.listBottom,
            ),
            children: [
              _buildHeader(),
              _gap,
              ..._buildMatchesSections(),
              ..._buildPlayersSections(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => AppCard(
        child: Row(
          children: [
            InitialsAvatar(name: widget.team.teamName, size: 56),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.team.teamName, style: AppTextStyles.pageTitle),
                  const SizedBox(height: 2),
                  Text(widget.event.name, style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      );

  // --------------- Partidos: balance, racha, próximos y resultados ---------------

  List<Widget> _buildMatchesSections() {
    final title = 'leagues.team_detail.record_title'.tr();
    switch (_notifier.matchesStatus) {
      case SummaryStatus.loading:
        return [TeamInEventSectionTitle(title), const SkeletonBox(height: 140), _gap];
      case SummaryStatus.failed:
        return [
          TeamInEventSectionTitle(title),
          TeamInEventMessage(
            message: 'leagues.team_detail.matches_error'.tr(),
            onRetry: _notifier.loadMatches,
          ),
          _gap,
        ];
      case SummaryStatus.ready:
        return _buildLoadedMatchesSections(title);
    }
  }

  List<Widget> _buildLoadedMatchesSections(String recordTitle) {
    final teamId = widget.team.teamId;
    final matches = splitTeamMatches(teamId, _notifier.eventMatches);
    if (matches.isEmpty) {
      return [
        TeamInEventSectionTitle(recordTitle),
        TeamInEventMessage(message: 'leagues.team_detail.no_matches'.tr()),
        _gap,
      ];
    }
    final limit = AppConstants.teamMatchesPreviewLimit.value;
    final record = buildTeamRecord(teamId, _notifier.eventMatches);
    final form = buildRecentForm(teamId, _notifier.eventMatches, limit: limit);
    return [
      if (!record.isEmpty) ...[
        TeamInEventSectionTitle(recordTitle),
        TeamRecordCard(record: record),
        const SizedBox(height: AppSpacing.lg),
        TeamInEventSectionTitle('reports.recent_form'.tr()),
        RecentFormChips(form: form),
        _gap,
      ],
      if (matches.upcoming.isNotEmpty) ...[
        TeamInEventSectionTitle('leagues.team_detail.upcoming_title'.tr()),
        ..._matchCards(matches.upcoming.take(limit)),
        _gap,
      ],
      if (matches.results.isNotEmpty) ...[
        TeamInEventSectionTitle('leagues.team_detail.results_title'.tr()),
        ..._matchCards(matches.results.take(limit)),
        _gap,
      ],
    ];
  }

  Iterable<Widget> _matchCards(Iterable<MatchModel> matches) => matches.map(
        (match) => MatchSummaryCard(
          match: match,
          homeName: _nameOf(match.homeTeamId, match.homeTeamName),
          awayName: _nameOf(match.awayTeamId, match.awayTeamName),
          onTap: () => _openMatch(match),
        ),
      );

  // --------------- Jugadores: goleadores, tarjetas y plantilla ---------------

  List<Widget> _buildPlayersSections() => [
        ..._buildStatsSections(),
        if (_notifier.rosterStatus == SummaryStatus.ready && _notifier.roster.isNotEmpty) ...[
          TeamInEventSectionTitle('mobile.teams.players'.tr()),
          TeamRosterList(players: sortCaptainFirst(_notifier.roster)),
        ],
      ];

  List<Widget> _buildStatsSections() {
    final scorersTitle = 'leagues.team_detail.scorers_title'.tr();
    switch (_notifier.statsStatus) {
      case SummaryStatus.loading:
        return [TeamInEventSectionTitle(scorersTitle), const SkeletonBox(height: 110), _gap];
      case SummaryStatus.failed:
        return [
          TeamInEventSectionTitle(scorersTitle),
          TeamInEventMessage(
            message: 'leagues.team_detail.stats_error'.tr(),
            onRetry: _notifier.loadStats,
          ),
          _gap,
        ];
      case SummaryStatus.ready:
        return _buildLoadedStatsSections(scorersTitle);
    }
  }

  List<Widget> _buildLoadedStatsSections(String scorersTitle) {
    final teamStats = filterStatsByScope(
      _notifier.eventStats,
      LeaderboardScope.myTeam,
      [widget.team.teamId],
    );
    final scorers = buildLeaderboard(teamStats, LeaderboardKind.scorers)
        .take(AppConstants.teamMatchesPreviewLimit.value)
        .toList();
    return [
      TeamInEventSectionTitle(scorersTitle),
      if (scorers.isEmpty)
        TeamInEventMessage(message: 'leagues.team_detail.scorers_empty'.tr())
      else
        TeamScorersList(scorers: scorers),
      const SizedBox(height: AppSpacing.lg),
      TeamInEventSectionTitle('leagues.team_detail.discipline_title'.tr()),
      TeamStatsCard(
        disciplineStatus: SummaryStatus.ready,
        discipline: buildTeamDiscipline(widget.team.teamId, [_notifier.eventStats]),
      ),
      _gap,
    ];
  }
}
