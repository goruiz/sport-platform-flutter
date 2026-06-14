import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';

class LeagueFab extends StatefulWidget {
  final TabController tabController;
  final VoidCallback onAddTeam;
  final VoidCallback onCreateMatch;
  final VoidCallback onAutoSchedule;

  const LeagueFab({
    super.key,
    required this.tabController,
    required this.onAddTeam,
    required this.onCreateMatch,
    required this.onAutoSchedule,
  });

  @override
  State<LeagueFab> createState() => _LeagueFabState();
}

class _LeagueFabState extends State<LeagueFab> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(_collapseOnTabChange);
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_collapseOnTabChange);
    super.dispose();
  }

  void _collapseOnTabChange() {
    if (_expanded && widget.tabController.index != 2) {
      setState(() => _expanded = false);
    }
  }

  void _toggle() => setState(() => _expanded = !_expanded);

  void _runAndCollapse(VoidCallback action) {
    setState(() => _expanded = false);
    action();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.tabController,
      builder: (_, _) => switch (widget.tabController.index) {
        1 => FloatingActionButton(
            onPressed: widget.onAddTeam,
            backgroundColor: AppColors.primaryLight,
            foregroundColor: AppColors.white,
            tooltip: 'leagues.add_team'.tr(),
            child: const Icon(Icons.group_add),
          ),
        2 => _MatchFabMenu(
            expanded: _expanded,
            onToggle: _toggle,
            onAutoSchedule: () => _runAndCollapse(widget.onAutoSchedule),
            onCreateMatch: () => _runAndCollapse(widget.onCreateMatch),
          ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

// ---------------------------------------------------------------------------

class _MatchFabMenu extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onAutoSchedule;
  final VoidCallback onCreateMatch;

  const _MatchFabMenu({
    required this.expanded,
    required this.onToggle,
    required this.onAutoSchedule,
    required this.onCreateMatch,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (expanded) ...[
          _MiniActionButton(
            label: 'leagues.auto_schedule_title'.tr(),
            icon: Icons.auto_awesome,
            onTap: onAutoSchedule,
          ),
          const SizedBox(height: 8),
          _MiniActionButton(
            label: 'leagues.new_match'.tr(),
            icon: Icons.edit_calendar_outlined,
            onTap: onCreateMatch,
          ),
          const SizedBox(height: 12),
        ],
        FloatingActionButton(
          onPressed: onToggle,
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.white,
          tooltip: 'leagues.new_match'.tr(),
          child: AnimatedRotation(
            turns: expanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

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
          child: Text(
            label,
            style: const TextStyle(color: AppColors.white, fontSize: 13),
          ),
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
