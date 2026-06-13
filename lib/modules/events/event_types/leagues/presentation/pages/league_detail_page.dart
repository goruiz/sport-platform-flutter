import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/league_detail_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/team_event_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/team_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/add_players_sheet.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/league_info_card.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/league_matches_tab.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/league_teams_tab.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/add_team_sheet.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/auto_schedule_sheet.dart';
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
  late EventModel _event;

  List<TeamEventModel> _teams = [];
  bool _loadingTeams = true;
  String? _teamsError;
  List<MatchModel> _matches = [];
  List<(DateTime, List<MatchModel>)> _groupedMatches = [];
  bool _loadingMatches = true;
  String? _matchesError;

  late final LeagueDetailService _detailService;

  @override
  void initState() {
    super.initState();
    _detailService = getIt<LeagueDetailService>();
    _event = widget.event;
    _tabController = TabController(length: 4, vsync: this);
    _loadTeams();
    _loadMatches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    setState(() {
      _loadingTeams = true;
      _teamsError = null;
    });
    try {
      final teams = await _detailService.getTeamsByEvent(_event.id);
      if (mounted) setState(() => _teams = teams);
    } catch (_) {
      if (mounted) setState(() => _teamsError = 'leagues.error_load_teams'.tr());
    } finally {
      if (mounted) setState(() => _loadingTeams = false);
    }
  }

  Future<void> _loadMatches() async {
    setState(() {
      _loadingMatches = true;
      _matchesError = null;
    });
    try {
      final matches = await _detailService.getMatchesByEvent(_event.id);
      if (mounted) {
        setState(() {
          _matches = matches;
          _groupedMatches = _groupByDate(matches);
        });
      }
    } catch (_) {
      if (mounted) setState(() => _matchesError = 'leagues.error_load_matches'.tr());
    } finally {
      if (mounted) setState(() => _loadingMatches = false);
    }
  }

  Future<void> _openManagePlayers(TeamEventModel team) async {
    await AddPlayersSheet.show(
      context: context,
      team: TeamModel(id: team.teamId, name: team.teamName),
      isEditMode: true,
    );
  }

  Future<void> _openAddTeam() async {
    final enrolledIds = _teams.map((t) => t.teamId).toSet();
    await AddTeamSheet.show(
      context: context,
      enrolledTeamIds: enrolledIds,
      onAdd: (teamId) async {
        final added = await _detailService.addTeam(teamId, _event.id);
        if (mounted) {
          setState(() => _teams.add(added));
          _showSnack('leagues.success_team_added'.tr());
        }
      },
    );
  }

  Future<void> _confirmRemoveTeam(TeamEventModel team) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'leagues.remove_team'.tr(),
      content: 'leagues.confirm_remove_team'.tr(args: [team.teamName]),
      confirmLabel: 'leagues.delete'.tr(),
      cancelLabel: 'leagues.cancel'.tr(),
    );
    if (!confirmed || !mounted) return;
    try {
      await _detailService.removeTeam(team.id);
      setState(() => _teams.removeWhere((t) => t.id == team.id));
      _showSnack('leagues.success_team_removed'.tr());
    } catch (_) {
      _showSnack('leagues.error_team_action'.tr(), isError: true);
    }
  }

  Future<void> _openCreateMatch() async {
    await MatchFormSheet.show(
      context: context,
      enrolledTeams: _teams,
      eventId: _event.id,
      onSave: (data) async {
        final created = await _detailService.createMatch(data);
        if (mounted) {
          setState(() {
            _matches.insert(0, created);
            _groupedMatches = _groupByDate(_matches);
          });
          _showSnack('leagues.success_match_created'.tr());
        }
      },
    );
  }

  Future<void> _openAutoSchedule() async {
    await AutoScheduleSheet.show(
      context: context,
      eventId: _event.id,
      onGenerated: (generated) async {
        if (mounted) {
          setState(() {
            _matches.addAll(generated);
            _groupedMatches = _groupByDate(_matches);
          });
        }
      },
    );
  }

  Future<void> _openEditMatch(MatchModel match) async {
    await MatchFormSheet.show(
      context: context,
      enrolledTeams: _teams,
      eventId: _event.id,
      match: match,
      onSave: (data) async {
        final updated = await _detailService.updateMatch(match.id, data);
        if (mounted) {
          setState(() {
            final idx = _matches.indexWhere((m) => m.id == match.id);
            if (idx != -1) _matches[idx] = updated;
            _groupedMatches = _groupByDate(_matches);
          });
          _showSnack('leagues.success_match_updated'.tr());
        }
      },
    );
  }

  Future<void> _confirmDeleteMatch(MatchModel match) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'leagues.confirm_delete_match'.tr(),
      confirmLabel: 'leagues.delete'.tr(),
      cancelLabel: 'leagues.cancel'.tr(),
    );
    if (!confirmed || !mounted) return;
    try {
      await _detailService.deleteMatch(match.id);
      setState(() {
        _matches.removeWhere((m) => m.id == match.id);
        _groupedMatches = _groupByDate(_matches);
      });
      _showSnack('leagues.success_match_deleted'.tr());
    } catch (_) {
      _showSnack('leagues.error_match_action'.tr(), isError: true);
    }
  }

  Future<void> _onRescheduleDay(DateTime fromDate, DateTime? toDate) async {
    try {
      final updated = await _detailService.rescheduleDateMatches(
          _event.id, fromDate,
          toDate: toDate);
      if (mounted) {
        setState(() {
          for (final u in updated) {
            final idx = _matches.indexWhere((m) => m.id == u.id);
            if (idx != -1) _matches[idx] = u;
          }
          _groupedMatches = _groupByDate(_matches);
        });
        _showSnack(toDate != null
            ? 'leagues.match_day_rescheduled'.tr()
            : 'leagues.match_day_postponed'.tr());
      }
    } catch (_) {
      if (mounted) _showSnack('leagues.match_day_error'.tr(), isError: true);
    }
  }

  List<(DateTime, List<MatchModel>)> _groupByDate(List<MatchModel> matches) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundEnd,
      appBar: AppBar(
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
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          LeagueTeamsTab(
            teams: _teams,
            isLoading: _loadingTeams,
            error: _teamsError,
            isOwner: widget.isOwner,
            onRetry: _loadTeams,
            onManagePlayers: _openManagePlayers,
            onRemove: _confirmRemoveTeam,
          ),
          LeagueMatchesTab(
            groupedMatches: _groupedMatches,
            teamMap: {for (final t in _teams) t.teamId: t.teamName},
            isLoading: _loadingMatches,
            error: _matchesError,
            isOwner: widget.isOwner,
            onRetry: _loadMatches,
            onEdit: _openEditMatch,
            onDelete: _confirmDeleteMatch,
            onRescheduleDay: _onRescheduleDay,
          ),
          _buildStandingsTab(),
        ],
      ),
      floatingActionButton: widget.isOwner
          ? _LeagueFab(
              tabController: _tabController,
              onAddTeam: _openAddTeam,
              onCreateMatch: _openCreateMatch,
              onAutoSchedule: _openAutoSchedule,
            )
          : null,
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

  Widget _buildStandingsTab() {
    if (_loadingTeams || _loadingMatches) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryLight));
    }
    return StandingsTab(teams: _teams, matches: _matches);
  }
}

// ---------------------------------------------------------------------------

class _LeagueFab extends StatefulWidget {
  final TabController tabController;
  final VoidCallback onAddTeam;
  final VoidCallback onCreateMatch;
  final VoidCallback onAutoSchedule;

  const _LeagueFab({
    required this.tabController,
    required this.onAddTeam,
    required this.onCreateMatch,
    required this.onAutoSchedule,
  });

  @override
  State<_LeagueFab> createState() => _LeagueFabState();
}

class _LeagueFabState extends State<_LeagueFab> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.tabController,
      builder: (_, _) {
        switch (widget.tabController.index) {
          case 1:
            return FloatingActionButton(
              onPressed: widget.onAddTeam,
              backgroundColor: AppColors.primaryLight,
              foregroundColor: AppColors.white,
              tooltip: 'leagues.add_team'.tr(),
              child: const Icon(Icons.group_add),
            );
          case 2:
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_expanded) ...[
                  _MiniActionButton(
                    label: 'leagues.auto_schedule_title'.tr(),
                    icon: Icons.auto_awesome,
                    onTap: () {
                      setState(() => _expanded = false);
                      widget.onAutoSchedule();
                    },
                  ),
                  const SizedBox(height: 8),
                  _MiniActionButton(
                    label: 'leagues.new_match'.tr(),
                    icon: Icons.edit_calendar_outlined,
                    onTap: () {
                      setState(() => _expanded = false);
                      widget.onCreateMatch();
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                FloatingActionButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.white,
                  tooltip: 'leagues.new_match'.tr(),
                  child: AnimatedRotation(
                    turns: _expanded ? 0.125 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _MiniActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Text(label,
              style: const TextStyle(color: AppColors.white, fontSize: 13)),
        ),
        const SizedBox(width: 8),
        FloatingActionButton.small(
          heroTag: label,
          onPressed: onTap,
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.white,
          child: Icon(icon, size: 18),
        ),
      ],
    );
  }
}

