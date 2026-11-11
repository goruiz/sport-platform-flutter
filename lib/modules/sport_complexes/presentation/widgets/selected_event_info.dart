import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/core/utils/date_formatters.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/shared/widgets/status_badge.dart';

/// Lo que se sabe del evento elegido en el selector, de un vistazo: cuándo se juega y en qué estado está.
class SelectedEventInfo extends StatelessWidget {
  final EventModel event;

  const SelectedEventInfo({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.sm, AppSpacing.page, 0),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined, size: 15, color: AppColors.whiteSubtle),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              DateFormatters.shortRange(event.startDate, event.endDate, context.locale.languageCode),
              style: AppTextStyles.caption,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusBadge.forEvent(event.status),
        ],
      ),
    );
  }
}
