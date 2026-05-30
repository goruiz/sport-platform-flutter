import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/events/leagues/data/models/match_model.dart';

class MatchCard extends StatelessWidget {
  final MatchModel match;
  final String homeTeamName;
  final String awayTeamName;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MatchCard({
    super.key,
    required this.match,
    required this.homeTeamName,
    required this.awayTeamName,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasActions = onEdit != null || onDelete != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TeamsRow(
                        homeTeamName: homeTeamName,
                        awayTeamName: awayTeamName,
                        homeScore: match.homeScore,
                        awayScore: match.awayScore,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: AppColors.whiteSubtle,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _fmtDateTime(match.matchDate),
                            style: const TextStyle(
                              color: AppColors.whiteSubtle,
                              fontSize: 12,
                            ),
                          ),
                          if (match.location != null &&
                              match.location!.isNotEmpty) ...[
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.location_on_outlined,
                              color: AppColors.whiteSubtle,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                match.location!,
                                style: const TextStyle(
                                  color: AppColors.whiteSubtle,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      _MatchStatusBadge(status: match.status),
                    ],
                  ),
                ),
                if (hasActions)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onEdit != null)
                        IconButton(
                          onPressed: onEdit,
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: AppColors.primaryLight,
                            size: 20,
                          ),
                          tooltip: 'common.edit'.tr(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 36, minHeight: 36),
                        ),
                      if (onDelete != null)
                        IconButton(
                          onPressed: onDelete,
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                            size: 20,
                          ),
                          tooltip: 'common.delete'.tr(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 36, minHeight: 36),
                        ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtDateTime(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _TeamsRow extends StatelessWidget {
  final String homeTeamName;
  final String awayTeamName;
  final int? homeScore;
  final int? awayScore;

  const _TeamsRow({
    required this.homeTeamName,
    required this.awayTeamName,
    this.homeScore,
    this.awayScore,
  });

  @override
  Widget build(BuildContext context) {
    final hasScore = homeScore != null && awayScore != null;
    return Row(
      children: [
        Expanded(
          child: Text(
            homeTeamName,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            hasScore ? '$homeScore — $awayScore' : 'vs',
            style: TextStyle(
              color: hasScore ? AppColors.primaryLight : AppColors.whiteSubtle,
              fontSize: hasScore ? 16 : 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            awayTeamName,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _MatchStatusBadge extends StatelessWidget {
  final String status;
  const _MatchStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(status);
    final label = _labelFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  static String _labelFor(String status) {
    const map = {
      'SCHEDULED': 'leagues.match_status_scheduled',
      'IN_PROGRESS': 'leagues.match_status_in_progress',
      'FINISHED': 'leagues.match_status_finished',
      'CANCELLED': 'leagues.match_status_cancelled',
    };
    final key = map[status.toUpperCase()];
    return key != null ? key.tr() : status;
  }

  static Color _colorFor(String status) {
    switch (status.toUpperCase()) {
      case 'SCHEDULED':
        return AppColors.primaryLight;
      case 'IN_PROGRESS':
        return AppColors.warning;
      case 'FINISHED':
        return AppColors.whiteSubtle;
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.whiteSubtle;
    }
  }
}
