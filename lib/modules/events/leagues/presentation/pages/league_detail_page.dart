import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/events/leagues/data/datasource/league_detail_service.dart';
import 'package:sport_platform/modules/events/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/leagues/data/models/team_event_model.dart';
import 'package:sport_platform/modules/events/leagues/presentation/widgets/add_team_sheet.dart';
import 'package:sport_platform/modules/events/leagues/presentation/widgets/match_card.dart';
import 'package:sport_platform/modules/events/leagues/presentation/widgets/match_form_sheet.dart';
import 'package:sport_platform/modules/events/leagues/presentation/widgets/team_event_card.dart';
import 'package:sport_platform/modules/events/shared/data/datasource/event_service.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/events/shared/presentation/widgets/event_form_sheet.dart';

class LeagueDetailPage extends StatefulWidget {
  final EventModel event;
  final bool isOwner;
  final EventService eventService;

  const LeagueDetailPage({
    super.key,
    required this.event,
    required this.isOwner,
    required this.eventService,
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
  bool _loadingMatches = true;
  String? _matchesError;

  final _detailService = LeagueDetailService();

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _tabController = TabController(length: 3, vsync: this);
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
      if (mounted) {
        setState(() => _teamsError = 'leagues.error_load_teams'.tr());
      }
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
      if (mounted) {
        setState(() => _matchesError = 'leagues.error_load_matches'.tr());
      }
    } finally {
      if (mounted) setState(() => _loadingMatches = false);
    }
  }

  Future<void> _openEditEvent() async {
    await EventFormSheet.show(
      context: context,
      translationPrefix: 'leagues',
      event: _event,
      onSave: (data) async {
        final updated = await widget.eventService.update(_event.id, data);
        if (mounted) {
          setState(() => _event = updated);
          _showSnack('leagues.success_updated'.tr());
        }
      },
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F2A0F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'leagues.remove_team'.tr(),
          style: const TextStyle(color: AppColors.white),
        ),
        content: Text(
          'leagues.confirm_remove_team'.tr(args: [team.teamName]),
          style: const TextStyle(color: AppColors.whiteSubtle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('leagues.cancel'.tr(),
                style: const TextStyle(color: AppColors.whiteSubtle)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('leagues.delete'.tr(),
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F2A0F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'leagues.confirm_delete_match'.tr(),
          style: const TextStyle(color: AppColors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('leagues.cancel'.tr(),
                style: const TextStyle(color: AppColors.whiteSubtle)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('leagues.delete'.tr(),
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _detailService.deleteMatch(match.id);
      setState(() => _matches.removeWhere((m) => m.id == match.id));
      _showSnack('leagues.success_match_deleted'.tr());
    } catch (_) {
      _showSnack('leagues.error_match_action'.tr(), isError: true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundEnd,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: Text(
          _event.name,
          style: const TextStyle(color: AppColors.white),
        ),
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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildTeamsTab(),
          _buildMatchesTab(),
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
        return FloatingActionButton(
          onPressed: _openCreateMatch,
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.white,
          tooltip: 'leagues.new_match'.tr(),
          child: const Icon(Icons.add),
        );
      default:
        return null;
    }
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoCard(event: _event),
          if (widget.isOwner) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openEditEvent,
                icon: const Icon(Icons.edit_outlined),
                label: Text('leagues.edit_item'.tr()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryLight,
                  side: const BorderSide(color: AppColors.primaryLight),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamsTab() {
    if (_loadingTeams) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryLight));
    }
    if (_teamsError != null) {
      return _ErrorRetry(message: _teamsError!, onRetry: _loadTeams);
    }
    if (_teams.isEmpty) {
      return _EmptyState(
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
          onRemove:
              widget.isOwner ? () => _confirmRemoveTeam(_teams[i]) : null,
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
      return _ErrorRetry(message: _matchesError!, onRetry: _loadMatches);
    }
    if (_matches.isEmpty) {
      return _EmptyState(
        icon: Icons.sports_score_outlined,
        title: 'leagues.matches_empty'.tr(),
        subtitle: 'leagues.matches_empty_subtitle'.tr(),
      );
    }

    final teamMap = {for (final t in _teams) t.teamId: t.teamName};

    return RefreshIndicator(
      onRefresh: _loadMatches,
      color: AppColors.primaryLight,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 100),
        itemCount: _matches.length,
        itemBuilder: (_, i) {
          final match = _matches[i];
          return MatchCard(
            match: match,
            homeTeamName: teamMap[match.homeTeamId] ?? match.homeTeamId,
            awayTeamName: teamMap[match.awayTeamId] ?? match.awayTeamId,
            onEdit: widget.isOwner ? () => _openEditMatch(match) : null,
            onDelete: widget.isOwner ? () => _confirmDeleteMatch(match) : null,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _InfoCard extends StatelessWidget {
  final EventModel event;
  const _InfoCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  event.name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _StatusChip(status: event.status),
            ],
          ),
          if (event.description != null &&
              event.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              event.description!,
              style: const TextStyle(
                  color: AppColors.whiteSubtle, fontSize: 14),
            ),
          ],
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.calendar_today,
            label:
                '${_fmt(event.startDate)} — ${_fmt(event.endDate)}',
          ),
          if (event.format.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.format_list_bulleted, label: event.format),
          ],
          if (event.eventTypeName != null &&
              event.eventTypeName!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(
                icon: Icons.military_tech, label: event.eventTypeName!),
          ],
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.access_time,
            label: _fmt(event.createdAt),
          ),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
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
            style: const TextStyle(
                color: AppColors.whiteSubtle, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        _labelFor(status),
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  static String _labelFor(String s) {
    const known = {'ACTIVE', 'UPCOMING', 'FINISHED', 'CANCELLED'};
    final key = s.toUpperCase();
    return known.contains(key)
        ? 'events.status_${key.toLowerCase()}'.tr()
        : s;
  }

  static Color _colorFor(String s) {
    switch (s.toUpperCase()) {
      case 'ACTIVE':
        return AppColors.success;
      case 'UPCOMING':
        return AppColors.primaryLight;
      case 'FINISHED':
        return AppColors.whiteSubtle;
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.whiteSubtle;
    }
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primaryLight.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: AppColors.primaryLight, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                  color: AppColors.whiteSubtle, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                  color: AppColors.whiteSubtle, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text('leagues.retry'.tr()),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryLight,
                side: const BorderSide(color: AppColors.primaryLight),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
