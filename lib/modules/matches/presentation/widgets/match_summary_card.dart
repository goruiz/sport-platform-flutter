import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/utils/date_formatters.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/shared/widgets/status_badge.dart';

/// El resumen de un partido en una lista: fecha, estado, equipos, marcador, evento y cancha.
/// Si [onTap] no es null la tarjeta se puede abrir para ver el detalle.
class MatchSummaryCard extends StatelessWidget {
  final MatchModel match;
  final String homeName;
  final String awayName;
  final String eventName;
  final String? courtName;
  final VoidCallback? onTap;

  const MatchSummaryCard({
    super.key,
    required this.match,
    required this.homeName,
    required this.awayName,
    this.eventName = '',
    this.courtName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 14),
                _buildTeams(),
                if (eventName.isNotEmpty || courtName != null) ...[
                  const SizedBox(height: 12),
                  _buildMetadata(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Row(
        children: [
          Expanded(
            child: Text(
              DateFormatters.dateTime(match.matchDate),
              style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 12),
            ),
          ),
          StatusBadge.forMatch(match.status),
        ],
      );

  Widget _buildTeams() => Row(
        children: [
          Expanded(child: _teamName(homeName, TextAlign.right)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              match.hasScore ? '${match.homeScore} - ${match.awayScore}' : 'VS',
              style: const TextStyle(
                color: AppColors.primaryLight,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: _teamName(awayName, TextAlign.left)),
        ],
      );

  Widget _teamName(String name, TextAlign align) => Text(
        name,
        textAlign: align,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
      );

  Widget _buildMetadata() => Wrap(
        spacing: 16,
        runSpacing: 6,
        children: [
          if (eventName.isNotEmpty)
            _Metadata(icon: Icons.emoji_events_outlined, text: eventName),
          if (courtName != null)
            _Metadata(icon: Icons.location_on_outlined, text: courtName!),
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
          Icon(icon, size: 14, color: AppColors.whiteSubtle),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 12),
            ),
          ),
        ],
      );
}
