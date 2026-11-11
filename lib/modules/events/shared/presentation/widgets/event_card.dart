import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/core/utils/date_formatters.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/shared/widgets/app_card.dart';
import 'package:sport_platform/shared/widgets/status_badge.dart';

/// Un evento en una lista: su nombre y formato, las fechas y, a la vista, en qué estado está
/// (en curso, por iniciar, finalizado).
class EventCard extends StatelessWidget {
  final EventModel event;
  final IconData typeIcon;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.event,
    this.typeIcon = Icons.sports,
    this.onTap,
  });

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
          _buildTitleRow(),
          const SizedBox(height: AppSpacing.md),
          _buildFooterRow(context),
        ],
      ),
    );
  }

  Widget _buildTitleRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(typeIcon, color: AppColors.primaryLight, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
              ),
              if (event.format.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(event.format, style: AppTextStyles.caption),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// La fecha a la izquierda y el estado a la derecha: lo primero que se quiere saber de un evento.
  Widget _buildFooterRow(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.calendar_today_outlined, size: 15, color: AppColors.whiteSubtle),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            DateFormatters.shortRange(
              event.startDate,
              event.endDate,
              context.locale.languageCode,
            ),
            style: AppTextStyles.caption,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        StatusBadge.forEvent(event.status),
      ],
    );
  }
}
