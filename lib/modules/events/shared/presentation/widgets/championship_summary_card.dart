import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/core/constants/locale_keys.g.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/events/shared/data/models/championship_model.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/championship_action.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/phase_status.dart';

/// Lo primero del campeonato: de qué formato es, en qué etapa va y qué sigue (o quién ganó).
class ChampionshipSummaryCard extends StatelessWidget {
  final ChampionshipModel championship;

  const ChampionshipSummaryCard({super.key, required this.championship});

  @override
  Widget build(BuildContext context) {
    final structure = championship.structure;
    final action = championship.nextStep?.action;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            championship.formatName ?? (structure?.translationKey.tr() ?? ''),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (structure != null && championship.formatName != null) ...[
            const SizedBox(height: AppSpacing.hairline),
            Text(
              structure.translationKey.tr(),
              style: AppTextStyles.footnote,
            ),
          ],
          if (championship.phases.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: championship.phases.map(_buildPhaseChip).toList(),
            ),
          ],
          const SizedBox(height: 14),
          if (championship.hasChampion)
            _buildChampion()
          else if (action != null)
            _buildNextStep(action),
        ],
      ),
    );
  }

  Widget _buildPhaseChip(PhaseModel phase) {
    final (icon, color) = switch (phase.status) {
      PhaseStatus.finished => (Icons.check_circle, AppColors.success),
      PhaseStatus.inProgress => (Icons.play_circle_fill, AppColors.warning),
      PhaseStatus.ready => (Icons.radio_button_unchecked, AppColors.primaryLight),
      PhaseStatus.pending => (Icons.hourglass_empty, AppColors.whiteSubtle),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.snug, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.tight),
          Text(
            phase.phase.translationKey.tr(),
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildChampion() {
    final name = championship.teamName(championship.championTeamId) ??
        LocaleKeys.championship_tbd.tr();
    return Row(
      children: [
        const Icon(Icons.emoji_events, color: AppColors.podiumGold, size: 28),
        const SizedBox(width: AppSpacing.snug),
        Expanded(
          child: Text(
            LocaleKeys.championship_champion.tr(args: [name]),
            style: const TextStyle(
              color: AppColors.podiumGold,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextStep(ChampionshipAction action) {
    final step = championship.nextStep!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.flag_outlined, color: AppColors.primaryLight, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            action.translationKey.tr(namedArgs: {
              'pending': '${step.pendingMatches}',
              'registered': '${step.registeredTeams}',
              'required': '${step.requiredTeams}',
            }),
            style: const TextStyle(color: AppColors.white, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
