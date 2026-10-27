import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/reports/domain/team_report.dart';

/// La racha reciente: un círculo por partido, del más viejo al más reciente (G, E o P).
class RecentFormChips extends StatelessWidget {
  final List<MatchResult> form;

  const RecentFormChips({super.key, required this.form});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, children: form.map(_chip).toList());
  }

  Widget _chip(MatchResult result) {
    final (label, color) = switch (result) {
      MatchResult.win => ('reports.form_win'.tr(), AppColors.success),
      MatchResult.draw => ('reports.form_draw'.tr(), AppColors.whiteSubtle),
      MatchResult.loss => ('reports.form_loss'.tr(), AppColors.error),
    };
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
