import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/enums/match_status.dart';
import 'package:sport_platform/modules/matches/presentation/widgets/match_scoreboard.dart';
import 'package:sport_platform/modules/matches/presentation/widgets/match_summary_card.dart';
import 'package:sport_platform/shared/widgets/app_card.dart';
import 'package:sport_platform/shared/widgets/status_badge.dart';

/// Un partido dentro de una jornada de la liga: el marcador (o la hora) con los escudos y, si hace falta,
/// el lugar y el estado. Las acciones de edición solo existen para quien gestiona la liga.
class MatchCard extends StatelessWidget {
  final MatchModel match;
  final String homeTeamName;
  final String awayTeamName;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onMatchPostpone;
  final VoidCallback? onMatchSuspend;
  final VoidCallback? onMatchReschedule;

  /// Abre el detalle del partido (cronología de goles y tarjetas).
  final VoidCallback? onTap;

  const MatchCard({
    super.key,
    required this.match,
    required this.homeTeamName,
    required this.awayTeamName,
    this.onEdit,
    this.onDelete,
    this.onMatchPostpone,
    this.onMatchSuspend,
    this.onMatchReschedule,
    this.onTap,
  });

  bool get _canPostponeOrSuspend =>
      match.status == MatchStatus.scheduled ||
      match.status == MatchStatus.rescheduled;

  bool get _canReschedule =>
      match.status == MatchStatus.postponed ||
      match.status == MatchStatus.suspended;

  bool get _hasStatusActions =>
      (_canPostponeOrSuspend || _canReschedule) &&
      (onMatchPostpone != null ||
          onMatchSuspend != null ||
          onMatchReschedule != null);

  bool get _hasOwnerActions => onEdit != null || onDelete != null;

  bool get _hasLocation => match.location != null && match.location!.isNotEmpty;

  bool get _showStatus => MatchSummaryCard.shouldShowStatus(match.status);

  bool get _hasHeader =>
      _hasLocation || _showStatus || _hasOwnerActions || _hasStatusActions;

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

  /// El lugar a la izquierda; a la derecha el estado (si no es lo normal) y las acciones de quien gestiona.
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
        if (onEdit != null)
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: AppColors.primaryLight, size: 20),
            tooltip: 'common.edit'.tr(),
            visualDensity: VisualDensity.compact,
          ),
        if (onDelete != null)
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
            tooltip: 'common.delete'.tr(),
            visualDensity: VisualDensity.compact,
          ),
        if (_hasStatusActions) _buildStatusActionsMenu(),
      ],
    );
  }

  Widget _buildStatusActionsMenu() {
    return PopupMenuButton<_MatchStatusAction>(
      onSelected: (action) {
        switch (action) {
          case _MatchStatusAction.postpone:
            onMatchPostpone?.call();
          case _MatchStatusAction.suspend:
            onMatchSuspend?.call();
          case _MatchStatusAction.reschedule:
            onMatchReschedule?.call();
        }
      },
      icon: const Icon(Icons.more_horiz, color: AppColors.whiteSubtle, size: 20),
      padding: EdgeInsets.zero,
      itemBuilder: (_) => [
        if (_canPostponeOrSuspend && onMatchPostpone != null)
          _statusActionItem(
            _MatchStatusAction.postpone,
            Icons.pause_circle_outline,
            AppColors.warningLight,
            'leagues.match_postpone'.tr(),
          ),
        if (_canPostponeOrSuspend && onMatchSuspend != null)
          _statusActionItem(
            _MatchStatusAction.suspend,
            Icons.block,
            AppColors.error,
            'leagues.match_suspend'.tr(),
          ),
        if (_canReschedule && onMatchReschedule != null)
          _statusActionItem(
            _MatchStatusAction.reschedule,
            Icons.edit_calendar_outlined,
            AppColors.primaryLight,
            'leagues.match_reschedule'.tr(),
          ),
      ],
    );
  }

  PopupMenuItem<_MatchStatusAction> _statusActionItem(
    _MatchStatusAction action,
    IconData icon,
    Color color,
    String label,
  ) {
    return PopupMenuItem(
      value: action,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppColors.white)),
        ],
      ),
    );
  }
}

enum _MatchStatusAction { postpone, suspend, reschedule }
