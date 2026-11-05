import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/enums/match_status.dart';
import 'package:sport_platform/modules/matches/presentation/widgets/match_scoreboard.dart';
import 'package:sport_platform/shared/widgets/app_card.dart';
import 'package:sport_platform/shared/widgets/status_badge.dart';

/// El resumen de un partido en una lista: el evento, los equipos con el marcador o la hora, y la cancha.
/// Si [onTap] no es null la tarjeta se puede abrir para ver el detalle.
class MatchSummaryCard extends StatelessWidget {
  final MatchModel match;
  final String homeName;
  final String awayName;
  final String eventName;
  final String? courtName;
  final VoidCallback? onTap;

  /// Escribe el día en la tarjeta. La lista de partidos lo apaga porque ya agrupa por día.
  final bool showDay;

  const MatchSummaryCard({
    super.key,
    required this.match,
    required this.homeName,
    required this.awayName,
    this.eventName = '',
    this.courtName,
    this.onTap,
    this.showDay = true,
  });

  /// Solo se rotula el estado cuando cuenta algo fuera de lo normal: un partido «programado» o «finalizado»
  /// ya se reconoce por llevar hora o marcador, y repetirlo en cada tarjeta es ruido.
  static bool shouldShowStatus(MatchStatus status) => switch (status) {
        MatchStatus.scheduled ||
        MatchStatus.finished ||
        MatchStatus.completed =>
          false,
        _ => true,
      };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_hasHeader) ...[
            _buildHeader(),
            const SizedBox(height: AppSpacing.md),
          ],
          MatchScoreboard(
            match: match,
            homeName: homeName,
            awayName: awayName,
            showDay: showDay,
          ),
          if (courtName != null) ...[
            const SizedBox(height: AppSpacing.md),
            _Metadata(icon: Icons.location_on_outlined, text: courtName!),
          ],
        ],
      ),
    );
  }

  bool get _hasHeader => eventName.isNotEmpty || shouldShowStatus(match.status);

  Widget _buildHeader() => Row(
        children: [
          Expanded(
            child: eventName.isEmpty
                ? const SizedBox.shrink()
                : _Metadata(icon: Icons.emoji_events_outlined, text: eventName),
          ),
          if (shouldShowStatus(match.status)) ...[
            const SizedBox(width: AppSpacing.sm),
            StatusBadge.forMatch(match.status),
          ],
        ],
      );
}

class _Metadata extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Metadata({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.whiteSubtle),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption,
            ),
          ),
        ],
      );
}
