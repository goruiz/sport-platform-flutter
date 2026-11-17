import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/core/constants/locale_keys.g.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/rankings/data/models/player_stats_model.dart';

/// Lo que hizo el propio jugador (en un evento o, con [subtitle], sumando varios): partidos jugados, goles, asistencias,
/// tarjetas y faltas.
class MyStatsCard extends StatelessWidget {
  final PlayerStatsModel stats;

  /// Aclara a qué corresponden los números cuando no es un solo evento.
  final String? subtitle;
  final EdgeInsetsGeometry margin;

  const MyStatsCard({
    super.key,
    required this.stats,
    this.subtitle,
    this.margin = const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xs),
  });

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_pin_outlined, color: AppColors.primaryLight, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                LocaleKeys.rankings_my_stats_title.tr(),
                style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle!, style: AppTextStyles.footnote),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _Counter(label: LocaleKeys.rankings_my_stats_matches.tr(), value: stats.matchesPlayed),
              _Counter(label: LocaleKeys.rankings_my_stats_goals.tr(), value: stats.goals),
              _Counter(label: LocaleKeys.rankings_my_stats_assists.tr(), value: stats.assists),
              _Counter(label: LocaleKeys.rankings_my_stats_yellow.tr(), value: stats.yellowCards, color: AppColors.cardYellow),
              _Counter(label: LocaleKeys.rankings_my_stats_red.tr(), value: stats.redCards, color: AppColors.cardRed),
              _Counter(label: LocaleKeys.rankings_my_stats_fouls.tr(), value: stats.fouls),
            ],
          ),
        ],
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _Counter({required this.label, required this.value, this.color = AppColors.white});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$value', style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.hairline),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: AppTextStyles.micro),
          ),
        ],
      ),
    );
  }
}
