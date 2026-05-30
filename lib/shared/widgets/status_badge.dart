import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';

/// Badge de estado reutilizable para eventos y partidos.
/// Usa [StatusBadge.forEvent] o [StatusBadge.forMatch] como constructores de fábrica.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool showDot;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.showDot = true,
  });

  factory StatusBadge.forEvent(String status, {Key? key}) {
    return StatusBadge(
      key: key,
      label: _eventLabel(status),
      color: _eventColor(status),
      showDot: true,
    );
  }

  factory StatusBadge.forEventChip(String status, {Key? key}) {
    return StatusBadge(
      key: key,
      label: _eventLabel(status),
      color: _eventColor(status),
      showDot: false,
    );
  }

  factory StatusBadge.forMatch(String status, {Key? key}) {
    return StatusBadge(
      key: key,
      label: _matchLabel(status),
      color: _matchColor(status),
      showDot: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: showDot ? 11 : 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  static String _eventLabel(String status) {
    const known = {'ACTIVE', 'UPCOMING', 'FINISHED', 'CANCELLED'};
    final key = status.toUpperCase();
    return known.contains(key) ? 'events.status_${key.toLowerCase()}'.tr() : status;
  }

  static Color _eventColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return AppColors.success;
      case 'UPCOMING':
        return AppColors.primaryLight;
      case 'FINISHED':
        return AppColors.whiteSubtle;
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.whiteSubtle;
    }
  }

  static String _matchLabel(String status) {
    const map = {
      'SCHEDULED': 'leagues.match_status_scheduled',
      'IN_PROGRESS': 'leagues.match_status_in_progress',
      'FINISHED': 'leagues.match_status_finished',
      'CANCELLED': 'leagues.match_status_cancelled',
    };
    final key = map[status.toUpperCase()];
    return key != null ? key.tr() : status;
  }

  static Color _matchColor(String status) {
    switch (status.toUpperCase()) {
      case 'SCHEDULED':
        return AppColors.primaryLight;
      case 'IN_PROGRESS':
        return AppColors.warning;
      case 'FINISHED':
        return AppColors.whiteSubtle;
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.whiteSubtle;
    }
  }
}
