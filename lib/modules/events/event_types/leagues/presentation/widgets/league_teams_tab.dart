import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/constants/locale_keys.g.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/team_event_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/team_event_card.dart';
import 'package:sport_platform/shared/widgets/empty_state.dart';
import 'package:sport_platform/shared/widgets/error_retry.dart';

class LeagueTeamsTab extends StatelessWidget {
  final List<TeamEventModel> teams;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  /// Abre el detalle de un equipo del evento.
  final void Function(TeamEventModel)? onOpen;

  const LeagueTeamsTab({
    super.key,
    required this.teams,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
          child: CircularProgressIndicator());
    }
    if (error != null) {
      return ErrorRetry(message: error!, onRetry: onRetry);
    }
    if (teams.isEmpty) {
      return EmptyState(
        icon: Icons.groups_outlined,
        title: LocaleKeys.leagues_teams_empty.tr(),
        subtitle: LocaleKeys.leagues_teams_empty_subtitle.tr(),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRetry(),
      color: AppColors.primaryLight,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.listBottom),
        itemCount: teams.length,
        itemBuilder: (_, i) => TeamEventCard(
          team: teams[i],
          onOpen: onOpen == null ? null : () => onOpen!(teams[i]),
        ),
      ),
    );
  }
}
