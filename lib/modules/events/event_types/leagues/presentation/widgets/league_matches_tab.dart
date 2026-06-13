import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/match_day_section.dart';
import 'package:sport_platform/shared/widgets/empty_state.dart';
import 'package:sport_platform/shared/widgets/error_retry.dart';

class LeagueMatchesTab extends StatelessWidget {
  final List<(DateTime, List<MatchModel>)> groupedMatches;
  final Map<String, String> teamMap;
  final bool isLoading;
  final String? error;
  final bool isOwner;
  final VoidCallback onRetry;
  final void Function(MatchModel) onEdit;
  final void Function(MatchModel) onDelete;
  final Future<void> Function(DateTime, DateTime?) onRescheduleDay;

  const LeagueMatchesTab({
    super.key,
    required this.groupedMatches,
    required this.teamMap,
    required this.isLoading,
    required this.error,
    required this.isOwner,
    required this.onRetry,
    required this.onEdit,
    required this.onDelete,
    required this.onRescheduleDay,
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
    if (groupedMatches.isEmpty) {
      return EmptyState(
        icon: Icons.sports_score_outlined,
        title: 'leagues.matches_empty'.tr(),
        subtitle: 'leagues.matches_empty_subtitle'.tr(),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRetry(),
      color: AppColors.primaryLight,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 100),
        itemCount: groupedMatches.length,
        itemBuilder: (_, i) {
          final (date, dayMatches) = groupedMatches[i];
          return MatchDaySection(
            dayIndex: i + 1,
            date: date,
            matches: dayMatches,
            teamMap: teamMap,
            isOwner: isOwner,
            onEdit: onEdit,
            onDelete: onDelete,
            onRescheduleDay: onRescheduleDay,
          );
        },
      ),
    );
  }
}
