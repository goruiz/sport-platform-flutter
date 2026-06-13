import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_input_decoration.dart';
import 'package:sport_platform/core/utils/date_formatters.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/league_detail_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/team_event_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/team_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/add_players_sheet.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/add_team_sheet.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/auto_schedule_sheet.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/match_day_section.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/match_form_sheet.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/standings_tab.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/team_event_card.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/events/shared/data/providers/events_notifier.dart';
import 'package:sport_platform/shared/widgets/confirmation_dialog.dart';
import 'package:sport_platform/shared/widgets/empty_state.dart';
import 'package:sport_platform/shared/widgets/error_retry.dart';

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
  bool _matchFabExpanded = false;

  List<MatchModel> _matches = [];
  bool _loadingMatches = true;
  String? _matchesError;

  late final LeagueDetailService _detailService;

  @override
  void initState() {
    super.initState();
    _detailService = getIt<LeagueDetailService>();
    _event = widget.event;
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
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
      if (mounted) setState(() => _matches = matches);
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
          setState(() => _matches.insert(0, created));
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
          setState(() => _matches.addAll(generated));
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
      setState(() => _matches.removeWhere((m) => m.id == match.id));
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
          _buildTeamsTab(),
          _buildMatchesTab(),
          _buildStandingsTab(),
        ],
      ),
      floatingActionButton: widget.isOwner ? _buildFab() : null,
    );
  }

  Widget? _buildFab() {
    switch (_tabController.index) {
      case 1:
        return FloatingActionButton(
          onPressed: _openAddTeam,
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.white,
          tooltip: 'leagues.add_team'.tr(),
          child: const Icon(Icons.group_add),
        );
      case 2:
        return _buildMatchFab();
      default:
        return null;
    }
  }

  Widget _buildMatchFab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_matchFabExpanded) ...[
          _MiniActionButton(
            label: 'leagues.auto_schedule_title'.tr(),
            icon: Icons.auto_awesome,
            onTap: () {
              setState(() => _matchFabExpanded = false);
              _openAutoSchedule();
            },
          ),
          const SizedBox(height: 8),
          _MiniActionButton(
            label: 'leagues.new_match'.tr(),
            icon: Icons.edit_calendar_outlined,
            onTap: () {
              setState(() => _matchFabExpanded = false);
              _openCreateMatch();
            },
          ),
          const SizedBox(height: 12),
        ],
        FloatingActionButton(
          onPressed: () => setState(() => _matchFabExpanded = !_matchFabExpanded),
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.white,
          tooltip: 'leagues.new_match'.tr(),
          child: AnimatedRotation(
            turns: _matchFabExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _InfoCard(
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
    if (_loadingTeams) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryLight));
    }
    if (_teamsError != null) {
      return ErrorRetry(message: _teamsError!, onRetry: _loadTeams);
    }
    if (_teams.isEmpty) {
      return EmptyState(
        icon: Icons.groups_outlined,
        title: 'leagues.teams_empty'.tr(),
        subtitle: 'leagues.teams_empty_subtitle'.tr(),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadTeams,
      color: AppColors.primaryLight,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 100),
        itemCount: _teams.length,
        itemBuilder: (_, i) => TeamEventCard(
          team: _teams[i],
          onManagePlayers: () => _openManagePlayers(_teams[i]),
          onRemove: widget.isOwner ? () => _confirmRemoveTeam(_teams[i]) : null,
        ),
      ),
    );
  }

  Widget _buildMatchesTab() {
    if (_loadingMatches) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryLight));
    }
    if (_matchesError != null) {
      return ErrorRetry(message: _matchesError!, onRetry: _loadMatches);
    }
    if (_matches.isEmpty) {
      return EmptyState(
        icon: Icons.sports_score_outlined,
        title: 'leagues.matches_empty'.tr(),
        subtitle: 'leagues.matches_empty_subtitle'.tr(),
      );
    }

    final teamMap = {for (final t in _teams) t.teamId: t.teamName};
    final groups = _groupByDate(_matches);

    return RefreshIndicator(
      onRefresh: _loadMatches,
      color: AppColors.primaryLight,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 100),
        itemCount: groups.length,
        itemBuilder: (_, i) {
          final (date, dayMatches) = groups[i];
          return MatchDaySection(
            dayIndex: i + 1,
            date: date,
            matches: dayMatches,
            teamMap: teamMap,
            isOwner: widget.isOwner,
            onEdit: _openEditMatch,
            onDelete: _confirmDeleteMatch,
            onRescheduleDay: _onRescheduleDay,
          );
        },
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

class _InfoCard extends StatefulWidget {
  final EventModel event;
  final bool isOwner;
  final Future<void> Function(Map<String, dynamic>) onSave;
  final VoidCallback onError;

  const _InfoCard({
    required this.event,
    required this.isOwner,
    required this.onSave,
    required this.onError,
  });

  @override
  State<_InfoCard> createState() => _InfoCardState();
}

class _InfoCardState extends State<_InfoCard> {
  bool _editing = false;
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _startDateCtrl;
  late final TextEditingController _endDateCtrl;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.event.name);
    _startDate = widget.event.startDate;
    _endDate = widget.event.endDate;
    _startDateCtrl =
        TextEditingController(text: DateFormatters.date(widget.event.startDate));
    _endDateCtrl =
        TextEditingController(text: DateFormatters.date(widget.event.endDate));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    super.dispose();
  }

  void _startEditing() => setState(() => _editing = true);

  void _cancelEditing() {
    setState(() {
      _editing = false;
      _nameCtrl.text = widget.event.name;
      _startDate = widget.event.startDate;
      _endDate = widget.event.endDate;
      _startDateCtrl.text = DateFormatters.date(widget.event.startDate);
      _endDateCtrl.text = DateFormatters.date(widget.event.endDate);
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? _startDate ?? DateTime.now());
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = date;
        _startDateCtrl.text = DateFormatters.date(date);
      } else {
        _endDate = date;
        _endDateCtrl.text = DateFormatters.date(date);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSave({
        'name': _nameCtrl.text.trim(),
        'startDate': DateFormatters.apiDate(_startDate!),
        'endDate': DateFormatters.apiDate(_endDate!),
      });
      if (mounted) setState(() => _editing = false);
    } catch (_) {
      if (mounted) widget.onError();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _editing ? AppColors.primaryLight : AppColors.inputBorder,
        ),
      ),
      child: _editing ? _buildEditMode() : _buildViewMode(),
    );
  }

  Widget _buildViewMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: widget.isOwner ? _startEditing : null,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.event.name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (widget.isOwner) ...[
                const SizedBox(width: 8),
                const Icon(Icons.edit_outlined,
                    color: AppColors.whiteSubtle, size: 16),
              ],
            ],
          ),
        ),
        if (widget.event.description != null &&
            widget.event.description!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            widget.event.description!,
            style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 14),
          ),
        ],
        const SizedBox(height: 16),
        GestureDetector(
          onTap: widget.isOwner ? _startEditing : null,
          behavior: HitTestBehavior.opaque,
          child: _InfoRow(
            icon: Icons.calendar_today,
            label:
                '${DateFormatters.date(widget.event.startDate)} - ${DateFormatters.date(widget.event.endDate)}',
          ),
        ),
        if (widget.event.format.isNotEmpty) ...[
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.format_list_bulleted, label: widget.event.format),
        ],
        if (widget.event.eventTypeName != null &&
            widget.event.eventTypeName!.isNotEmpty) ...[
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.military_tech, label: widget.event.eventTypeName!),
        ],
        const SizedBox(height: 8),
        _InfoRow(
          icon: Icons.access_time,
          label: DateFormatters.date(widget.event.createdAt),
        ),
      ],
    );
  }

  Widget _buildEditMode() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameCtrl,
            autofocus: true,
            style: const TextStyle(color: AppColors.white),
            decoration: AppInputDecoration.standard('leagues.name'.tr()),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'leagues.name_required'.tr()
                : null,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _startDateCtrl,
                  readOnly: true,
                  onTap: () => _pickDate(isStart: true),
                  style: const TextStyle(color: AppColors.white),
                  decoration:
                      AppInputDecoration.standard('leagues.start_date'.tr())
                          .copyWith(
                    suffixIcon: const Icon(Icons.calendar_today,
                        color: AppColors.whiteSubtle, size: 18),
                  ),
                  validator: (_) => _startDate == null
                      ? 'leagues.start_date_required'.tr()
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _endDateCtrl,
                  readOnly: true,
                  onTap: () => _pickDate(isStart: false),
                  style: const TextStyle(color: AppColors.white),
                  decoration:
                      AppInputDecoration.standard('leagues.end_date'.tr())
                          .copyWith(
                    suffixIcon: const Icon(Icons.calendar_today,
                        color: AppColors.whiteSubtle, size: 18),
                  ),
                  validator: (_) {
                    if (_endDate == null) {
                      return 'leagues.end_date_required'.tr();
                    }
                    if (_startDate != null && _endDate!.isBefore(_startDate!)) {
                      return 'leagues.date_order_error'.tr();
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          if (widget.event.format.isNotEmpty) ...[
            const SizedBox(height: 16),
            _InfoRow(
                icon: Icons.format_list_bulleted, label: widget.event.format),
          ],
          if (widget.event.eventTypeName != null &&
              widget.event.eventTypeName!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(
                icon: Icons.military_tech, label: widget.event.eventTypeName!),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : _cancelEditing,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.inputBorder),
                    foregroundColor: AppColors.whiteSubtle,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('leagues.cancel'.tr()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.white),
                        )
                      : Text('leagues.save'.tr(),
                          style: const TextStyle(color: AppColors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.whiteSubtle, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
