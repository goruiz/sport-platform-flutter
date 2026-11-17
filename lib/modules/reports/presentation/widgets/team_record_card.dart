import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/core/constants/locale_keys.g.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/reports/domain/team_report.dart';

/// El balance del equipo: partidos jugados, ganados, empatados y perdidos, y los goles.
class TeamRecordCard extends StatelessWidget {
  final TeamRecord record;

  const TeamRecordCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(label: LocaleKeys.reports_played.tr(), value: '${record.played}'),
              _Stat(
                label: LocaleKeys.reports_won.tr(),
                value: '${record.won}',
                color: AppColors.success,
              ),
              _Stat(label: LocaleKeys.reports_drawn.tr(), value: '${record.drawn}'),
              _Stat(
                label: LocaleKeys.reports_lost.tr(),
                value: '${record.lost}',
                color: AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: record.winRate,
              minHeight: 8,
              backgroundColor: AppColors.inputBorder,
              color: AppColors.primaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.tight),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              LocaleKeys.reports_win_rate.tr(
                args: ['${(record.winRate * 100).round()}'],
              ),
              style: AppTextStyles.footnote,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(
                label: LocaleKeys.reports_goals_for.tr(),
                value: '${record.goalsFor}',
              ),
              _Stat(
                label: LocaleKeys.reports_goals_against.tr(),
                value: '${record.goalsAgainst}',
              ),
              _Stat(
                label: LocaleKeys.reports_goal_difference.tr(),
                value: record.goalDifference > 0
                    ? '+${record.goalDifference}'
                    : '${record.goalDifference}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Stat({
    required this.label,
    required this.value,
    this.color = AppColors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.hairline),
        Text(
          label,
          style: AppTextStyles.footnote,
        ),
      ],
    );
  }
}
