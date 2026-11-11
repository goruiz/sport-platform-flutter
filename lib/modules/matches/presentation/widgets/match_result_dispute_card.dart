import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/modules/matches/data/models/match_dispute_model.dart';
import 'package:sport_platform/modules/matches/domain/match_dispute_rules.dart';
import 'package:sport_platform/shared/widgets/app_card.dart';
import 'package:sport_platform/shared/widgets/status_badge.dart';

/// «¿Hay un problema con el resultado?»: el dirigente avisa al organizador y ve en qué va su aviso. Solo dibuja y avisa:
/// quien la usa lee los avisos y abre el formulario.
class MatchResultDisputeCard extends StatelessWidget {
  /// Los avisos del equipo del dirigente en este partido, de más nuevo a más antiguo.
  final List<MatchDisputeModel> disputes;

  /// Nombres de local y visitante, para decir a cuál equipo corresponde el marcador que propuso.
  final String homeName;
  final String awayName;
  final bool isSaving;
  final VoidCallback onReport;

  const MatchResultDisputeCard({
    super.key,
    required this.disputes,
    required this.homeName,
    required this.awayName,
    required this.isSaving,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    context.locale;
    final state = DisputeCardState.of(disputes);
    final latest = state.latest;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline, color: AppColors.primaryLight, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text('match_detail.dispute.title'.tr(), style: AppTextStyles.cardTitle)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (latest == null)
            Text('match_detail.dispute.hint'.tr(), style: AppTextStyles.bodyMuted)
          else
            _buildLatestDispute(latest),
          if (state.canOpenNew) ...[
            const SizedBox(height: AppSpacing.lg),
            _buildReportButton(isFirst: latest == null),
          ],
        ],
      ),
    );
  }

  Widget _buildReportButton({required bool isFirst}) {
    final label = Text(
      (isFirst ? 'match_detail.dispute.report' : 'match_detail.dispute.report_again').tr(),
      textAlign: TextAlign.center,
    );
    final icon = const Icon(Icons.campaign_outlined, size: 18);
    final onPressed = isSaving ? null : onReport;
    return SizedBox(
      width: double.infinity,
      child: isFirst
          ? FilledButton.icon(onPressed: onPressed, icon: icon, label: label)
          : OutlinedButton.icon(onPressed: onPressed, icon: icon, label: label),
    );
  }

  /// El aviso: en qué va, lo que se contó, el marcador que se propuso y lo que respondió el organizador.
  Widget _buildLatestDispute(MatchDisputeModel dispute) {
    final note = dispute.resolutionNote?.trim() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusBadge(dispute.status),
        const SizedBox(height: AppSpacing.md),
        Text(
          'match_detail.dispute.your_reason'.tr(namedArgs: {'reason': dispute.reason}),
          style: AppTextStyles.body,
        ),
        if (dispute.hasProposedScore) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'match_detail.dispute.proposed_score'.tr(
              namedArgs: {
                'home': homeName,
                'homeScore': '${dispute.proposedHomeScore}',
                'awayScore': '${dispute.proposedAwayScore}',
                'away': awayName,
              },
            ),
            style: AppTextStyles.caption,
          ),
        ],
        if (note.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'match_detail.dispute.organizer_note'.tr(namedArgs: {'note': note}),
            style: AppTextStyles.bodyMuted,
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(DisputeStatus status) {
    return switch (status) {
      DisputeStatus.open => StatusBadge(label: 'match_detail.dispute.status_open'.tr(), color: AppColors.warning),
      DisputeStatus.accepted => StatusBadge(label: 'match_detail.dispute.status_accepted'.tr(), color: AppColors.success),
      DisputeStatus.rejected => StatusBadge(label: 'match_detail.dispute.status_rejected'.tr(), color: AppColors.info),
    };
  }
}
