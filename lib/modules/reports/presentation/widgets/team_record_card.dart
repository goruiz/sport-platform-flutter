import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/reports/domain/team_report.dart';

/// El balance del equipo: partidos jugados, ganados, empatados y perdidos, y los goles.
class TeamRecordCard extends StatelessWidget {
  final TeamRecord record;

  const TeamRecordCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(label: 'reports.played'.tr(), value: '${record.played}'),
              _Stat(
                label: 'reports.won'.tr(),
                value: '${record.won}',
                color: AppColors.success,
              ),
              _Stat(label: 'reports.drawn'.tr(), value: '${record.drawn}'),
              _Stat(
                label: 'reports.lost'.tr(),
                value: '${record.lost}',
                color: AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: record.winRate,
              minHeight: 8,
              backgroundColor: AppColors.inputBorder,
              color: AppColors.primaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'reports.win_rate'.tr(
                args: ['${(record.winRate * 100).round()}'],
              ),
              style: const TextStyle(
                color: AppColors.whiteSubtle,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(
                label: 'reports.goals_for'.tr(),
                value: '${record.goalsFor}',
              ),
              _Stat(
                label: 'reports.goals_against'.tr(),
                value: '${record.goalsAgainst}',
              ),
              _Stat(
                label: 'reports.goal_difference'.tr(),
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
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 12),
        ),
      ],
    );
  }
}
