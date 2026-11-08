import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/matches/presentation/widgets/match_summary_card.dart';
import 'package:sport_platform/shared/enums/summary_status.dart';
import 'package:sport_platform/shared/widgets/app_card.dart';
import 'package:sport_platform/shared/widgets/skeleton_box.dart';

/// Los partidos que vienen en una cancha. Solo dibuja y avisa: la lectura la hace quien la use.
class CourtUpcomingMatchesSection extends StatelessWidget {
  final SummaryStatus status;
  final List<MatchModel> matches;
  final ValueChanged<MatchModel> onMatchTap;
  final VoidCallback onRetry;

  const CourtUpcomingMatchesSection({
    super.key,
    required this.status,
    required this.matches,
    required this.onMatchTap,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    context.locale;
    return switch (status) {
      SummaryStatus.loading => const SkeletonBox(height: 110),
      SummaryStatus.failed => _buildMessage('mobile.courts.upcoming_error'.tr(), withRetry: true),
      SummaryStatus.ready when matches.isEmpty => _buildMessage('mobile.courts.upcoming_empty'.tr()),
      SummaryStatus.ready => Column(
          children: [
            for (final match in matches)
              MatchSummaryCard(
                match: match,
                homeName: match.homeTeamName ?? '—',
                awayName: match.awayTeamName ?? '—',
                eventName: match.eventName ?? '',
                onTap: () => onMatchTap(match),
              ),
          ],
        ),
    };
  }

  Widget _buildMessage(String message, {bool withRetry = false}) => AppCard(
        child: Row(
          children: [
            Expanded(child: Text(message, style: AppTextStyles.bodyMuted)),
            if (withRetry)
              TextButton(onPressed: onRetry, child: Text('common.retry'.tr())),
          ],
        ),
      );
}
