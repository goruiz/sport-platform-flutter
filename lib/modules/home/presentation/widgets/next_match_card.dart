import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/matches/presentation/widgets/match_scoreboard.dart';
import 'package:sport_platform/shared/widgets/app_card.dart';

/// El partido destacado del inicio: quién juega, cuándo y dónde, en grande y de un vistazo.
class NextMatchCard extends StatelessWidget {
  final MatchModel match;
  final String homeName;
  final String awayName;
  final String eventName;
  final VoidCallback? onTap;

  const NextMatchCard({
    super.key,
    required this.match,
    required this.homeName,
    required this.awayName,
    this.eventName = '',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final place = match.location;
    return AppCard(
      accent: AppColors.primaryLight,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
      child: Column(
        children: [
          if (eventName.isNotEmpty) ...[
            Text(
              eventName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          MatchScoreboard(
            match: match,
            homeName: homeName,
            awayName: awayName,
            large: true,
          ),
          if (place != null && place.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.whiteSubtle),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    place,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
