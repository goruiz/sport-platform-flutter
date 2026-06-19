import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/team_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/repositories/i_league_matches_repository.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/repositories/i_league_teams_repository.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/providers/league_detail_notifier.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/add_players_sheet.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/add_team_sheet.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/auto_schedule_sheet.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/league_fab.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/league_info_card.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/league_matches_tab.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/league_teams_tab.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/match_form_sheet.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/standings_tab.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/events/shared/data/providers/events_notifier.dart';
import 'package:sport_platform/shared/widgets/confirmation_dialog.dart';

class LeagueDetailPage extends StatefulWidget {
  final EventModel event;
  final bool isOwner;

  const LeagueDetailPage({
    super.key,
    required this.event,
    required this.isOwner,
  });

  @override
  State<LeagueDetailPage> createState() => _LeagueDetailPageState();
}

class _LeagueDetailPageState extends State<LeagueDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final LeagueDetailNotifier _notifier;
  late EventModel _event;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
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

  // --------------- Teams ---------------

  Future<void> _openManagePlayers(String teamId, String teamName) =>
      AddPlayersSheet.show(
        context: context,
        team: TeamModel(id: teamId, name: teamName),
        isEditMode: true,
      );

  Future<void> _openAddTeam() async {
    final enrolledIds = _notifier.teams.map((t) => t.teamId).toSet();
    await AddTeamSheet.show(
      context: context,
      enrolledTeamIds: enrolledIds,
      onAdd: (teamId) async {
        await _notifier.addTeam(teamId);
        if (mounted) _showSnack('leagues.success_team_added'.tr());
      },
    );
  }

  Future<void> _confirmRemoveTeam(String teamsEventsId, String teamName) =>
      _confirmAndExecute(
        title: 'leagues.remove_team'.tr(),
        content: 'leagues.confirm_remove_team'.tr(args: [teamName]),
        confirmLabel: 'leagues.delete'.tr(),
        cancelLabel: 'leagues.cancel'.tr(),
        action: () => _notifier.removeTeam(teamsEventsId),
        successMessage: 'leagues.success_team_removed'.tr(),
        errorMessage: 'leagues.error_team_action'.tr(),
      );

  // --------------- Matches ---------------

  Future<void> _openCreateMatch() => MatchFormSheet.show(
        context: context,
        enrolledTeams: _notifier.teams,
        eventId: _event.id,
        onSave: (data) async {
          await _notifier.createMatch(data);
          if (mounted) _showSnack('leagues.success_match_created'.tr());
        },
      );

  Future<void> _openAutoSchedule() => AutoScheduleSheet.show(
        context: context,
        eventId: _event.id,
        onGenerated: (generated) async => _notifier.addGeneratedMatches(generated),
      );

  Future<void> _openEditMatch(MatchModel match) => MatchFormSheet.show(
        context: context,
        enrolledTeams: _notifier.teams,
        eventId: _event.id,
        match: match,
        onSave: (data) async {
          await _notifier.updateMatch(match.id, data);
          if (mounted) _showSnack('leagues.success_match_updated'.tr());
        },
      );

  Future<void> _confirmDeleteMatch(MatchModel match) => _confirmAndExecute(
        title: 'leagues.confirm_delete_match'.tr(),
        confirmLabel: 'leagues.delete'.tr(),
        cancelLabel: 'leagues.cancel'.tr(),
        action: () => _notifier.deleteMatch(match.id),
        successMessage: 'leagues.success_match_deleted'.tr(),
        errorMessage: 'leagues.error_match_action'.tr(),
      );

  Future<void> _onRescheduleDay(DateTime fromDate, DateTime? toDate) async {
    try {
      await _notifier.rescheduleDateMatches(fromDate, toDate: toDate);
      if (mounted) {
        _showSnack(toDate != null
            ? 'leagues.match_day_rescheduled'.tr()
            : 'leagues.match_day_postponed'.tr());
      }
    } catch (_) {
      if (mounted) _showSnack('leagues.match_day_error'.tr(), isError: true);
    }
  }

  // --------------- Helpers ---------------

  Future<void> _confirmAndExecute({
    required String title,
    String? content,
    required String confirmLabel,
    required String cancelLabel,
    required Future<void> Function() action,
    required String successMessage,
    required String errorMessage,
  }) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: title,
      content: content,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    );
    if (!confirmed || !mounted) return;
    try {
      await action();
      if (mounted) _showSnack(successMessage);
    } catch (_) {
      if (mounted) _showSnack(errorMessage, isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // --------------- Build ---------------

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _notifier,
      builder: (context, _) => Scaffold(
        backgroundColor: AppColors.backgroundEnd,
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
        floatingActionButton: widget.isOwner
            ? LeagueFab(
                tabController: _tabController,
                onAddTeam: _openAddTeam,
                onCreateMatch: _openCreateMatch,
                onAutoSchedule: _openAutoSchedule,
              )
            : null,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryDark,
      title: Text(_event.name, style: const TextStyle(color: AppColors.white)),
      iconTheme: const IconThemeData(color: AppColors.white),
      elevation: 0,
      bottom: TabBar(
        controller: _tabController,
        labelColor: AppColors.primaryLight,
        unselectedLabelColor: AppColors.whiteSubtle,
        indicatorColor: AppColors.primaryLight,
        dividerColor: AppColors.inputBorder,
        tabs: [
          Tab(text: 'leagues.detail_tab_info'.tr()),
          Tab(text: 'leagues.detail_tab_teams'.tr()),
          Tab(text: 'leagues.detail_tab_matches'.tr()),
          Tab(text: 'leagues.detail_tab_standings'.tr()),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: LeagueInfoCard(
        event: _event,
        isOwner: widget.isOwner,
        onSave: (data) async {
          final notifier = getIt<EventsNotifier>(instanceName: 'leagues');
          final updated = await notifier.update(_event.id, data);
          if (mounted) {
            setState(() => _event = updated);
            _showSnack('leagues.success_updated'.tr());
          }
        },
        onError: () => _showSnack('leagues.error_update'.tr(), isError: true),
      ),
    );
  }

  Widget _buildTeamsTab() {
    return LeagueTeamsTab(
      teams: _notifier.teams,
      isLoading: _notifier.loadingTeams,
      error: _notifier.teamsError?.tr(),
      isOwner: widget.isOwner,
      onRetry: _notifier.loadTeams,
      onManagePlayers: (team) => _openManagePlayers(team.teamId, team.teamName),
      onRemove: (team) => _confirmRemoveTeam(team.id, team.teamName),
    );
  }

  Widget _buildMatchesTab() {
    return LeagueMatchesTab(
      groupedMatches: _notifier.groupedMatches,
      teamMap: {for (final t in _notifier.teams) t.teamId: t.teamName},
      isLoading: _notifier.loadingMatches,
      error: _notifier.matchesError?.tr(),
      isOwner: widget.isOwner,
      onRetry: _notifier.loadMatches,
      onEdit: _openEditMatch,
      onDelete: _confirmDeleteMatch,
      onRescheduleDay: _onRescheduleDay,
    );
  }

  Widget _buildStandingsTab() {
    if (_notifier.loadingTeams || _notifier.loadingMatches) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryLight),
      );
    }
    return StandingsTab(eventId: _event.id);
  }
}
