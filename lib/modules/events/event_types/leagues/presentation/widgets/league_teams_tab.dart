import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/team_event_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/team_event_card.dart';
import 'package:sport_platform/shared/widgets/empty_state.dart';
import 'package:sport_platform/shared/widgets/error_retry.dart';

class LeagueTeamsTab extends StatelessWidget {
  final List<TeamEventModel> teams;
  final bool isLoading;
  final String? error;
  final bool isOwner;
  final VoidCallback onRetry;
  final void Function(TeamEventModel) onManagePlayers;
  final void Function(TeamEventModel)? onRemove;

  const LeagueTeamsTab({
    super.key,
    required this.teams,
    required this.isLoading,
    required this.error,
    required this.isOwner,
    required this.onRetry,
    required this.onManagePlayers,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryLight));
    }
    if (error != null) {
      return ErrorRetry(message: error!, onRetry: onRetry);
    }
    if (teams.isEmpty) {
      return EmptyState(
        icon: Icons.groups_outlined,
        title: 'leagues.teams_empty'.tr(),
        subtitle: 'leagues.teams_empty_subtitle'.tr(),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRetry(),
      color: AppColors.primaryLight,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 100),
        itemCount: teams.length,
        itemBuilder: (_, i) => TeamEventCard(
          team: teams[i],
          onManagePlayers: () => onManagePlayers(teams[i]),
          onRemove: isOwner ? () => onRemove?.call(teams[i]) : null,
        ),
      ),
    );
  }
}
