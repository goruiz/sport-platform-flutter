import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/core/utils/date_formatters.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/shared/widgets/status_badge.dart';

/// El encabezado de un evento sobre sus complejos: cuál es, cuándo se juega y en qué estado está.
class EventSectionHeader extends StatelessWidget {
  final EventModel event;

  const EventSectionHeader({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.xl, AppSpacing.page, AppSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_outlined, color: AppColors.primaryLight, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.sectionTitle),
                const SizedBox(height: 2),
                Text(
                  DateFormatters.shortRange(event.startDate, event.endDate, context.locale.languageCode),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusBadge.forEvent(event.status),
        ],
      ),
    );
  }
}
