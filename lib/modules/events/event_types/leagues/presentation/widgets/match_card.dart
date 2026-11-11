import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/matches/presentation/widgets/match_scoreboard.dart';
import 'package:sport_platform/modules/matches/presentation/widgets/match_summary_card.dart';
import 'package:sport_platform/shared/widgets/app_card.dart';
import 'package:sport_platform/shared/widgets/status_badge.dart';

/// Un partido dentro de una jornada de la liga: el marcador (o la hora) con los escudos y, si hace falta,
/// el lugar y el estado.
class MatchCard extends StatelessWidget {
  final MatchModel match;
  final String homeTeamName;
  final String awayTeamName;

  /// Abre el detalle del partido (cronología de goles y tarjetas).
  final VoidCallback? onTap;

  const MatchCard({
    super.key,
    required this.match,
    required this.homeTeamName,
    required this.awayTeamName,
    this.onTap,
  });

  bool get _hasLocation => match.location != null && match.location!.isNotEmpty;

  bool get _showStatus => MatchSummaryCard.shouldShowStatus(match.status);

  bool get _hasHeader => _hasLocation || _showStatus;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.page,
        vertical: AppSpacing.xs + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_hasHeader) ...[
            _buildHeader(),
            const SizedBox(height: AppSpacing.sm),
          ],
          // El día ya está en el encabezado de la jornada.
          MatchScoreboard(
            match: match,
            homeName: homeTeamName,
            awayName: awayTeamName,
            showDay: false,
          ),
        ],
      ),
    );
  }

  /// El lugar a la izquierda; a la derecha el estado (si no es lo normal).
  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: _hasLocation
              ? Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: AppColors.whiteSubtle, size: 15),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        match.location!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
        if (_showStatus) StatusBadge.forMatch(match.status),
      ],
    );
  }
}
