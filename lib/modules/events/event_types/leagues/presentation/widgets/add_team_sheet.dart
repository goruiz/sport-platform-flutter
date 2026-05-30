import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_input_decoration.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/teams_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/team_model.dart';
import 'package:sport_platform/shared/widgets/sheet_handle.dart';

class AddTeamSheet extends StatefulWidget {
  final Set<String> enrolledTeamIds;
  final Future<void> Function(String teamId) onAdd;

  const AddTeamSheet({
    super.key,
    required this.enrolledTeamIds,
    required this.onAdd,
  });

  static Future<void> show({
    required BuildContext context,
    required Set<String> enrolledTeamIds,
    required Future<void> Function(String teamId) onAdd,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTeamSheet(
        enrolledTeamIds: enrolledTeamIds,
        onAdd: onAdd,
      ),
    );
  }

  @override
  State<AddTeamSheet> createState() => _AddTeamSheetState();
}

class _AddTeamSheetState extends State<AddTeamSheet> {
  late final TeamsService _teamsService;
  final _searchCtrl = TextEditingController();

  List<TeamModel> _allTeams = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  String? _addingTeamId;

  @override
  void initState() {
    super.initState();
    _teamsService = getIt<TeamsService>();
    _loadTeams();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final teams = await _teamsService.getAll();
      if (mounted) setState(() => _allTeams = teams);
    } catch (_) {
      if (mounted) setState(() => _error = 'leagues.error_load_teams'.tr());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<TeamModel> get _filtered {
    final available =
        _allTeams.where((t) => !widget.enrolledTeamIds.contains(t.id)).toList();
    if (_query.isEmpty) return available;
    final q = _query.toLowerCase();
    return available.where((t) => t.name.toLowerCase().contains(q)).toList();
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

  Future<void> _add(TeamModel team) async {
    setState(() => _addingTeamId = team.id);
    try {
      await widget.onAdd(team.id);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _addingTeamId = null);
        _showSnack('leagues.error_team_action'.tr(), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.sheetBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          const SizedBox(height: 20),
          Text(
            'leagues.add_team'.tr(),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: AppColors.white),
            decoration: AppInputDecoration.standard('leagues.search_team'.tr())
                .copyWith(
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.whiteSubtle),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          Flexible(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: AppColors.primaryLight),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!,
                  style: const TextStyle(
                      color: AppColors.whiteSubtle, fontSize: 14)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loadTeams,
                icon: const Icon(Icons.refresh),
                label: Text('leagues.retry'.tr()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryLight,
                  side: const BorderSide(color: AppColors.primaryLight),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final teams = _filtered;
    if (teams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'leagues.teams_empty'.tr(),
            style:
                const TextStyle(color: AppColors.whiteSubtle, fontSize: 14),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: teams.length,
      itemBuilder: (_, i) {
        final team = teams[i];
        final isAdding = _addingTeamId == team.id;
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.groups_outlined,
                color: AppColors.primaryLight, size: 20),
          ),
          title: Text(team.name,
              style: const TextStyle(color: AppColors.white, fontSize: 15)),
          trailing: isAdding
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primaryLight),
                )
              : const Icon(Icons.add_circle_outline,
                  color: AppColors.primaryLight),
          onTap: isAdding ? null : () => _add(team),
        );
      },
    );
  }
}
