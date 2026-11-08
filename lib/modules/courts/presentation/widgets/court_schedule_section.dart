import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/core/utils/date_formatters.dart';
import 'package:sport_platform/modules/courts/data/models/court_availability_model.dart';
import 'package:sport_platform/modules/courts/domain/court_agenda.dart';
import 'package:sport_platform/shared/enums/summary_status.dart';
import 'package:sport_platform/shared/widgets/app_card.dart';
import 'package:sport_platform/shared/widgets/skeleton_box.dart';

/// Los horarios de una cancha en el día elegido: los días para escoger y, debajo, qué tramos están libres y cuáles
/// ocupa un partido. Solo dibuja y avisa: la lectura la hace quien la use.
class CourtScheduleSection extends StatelessWidget {
  final List<DateTime> days;
  final DateTime selectedDay;
  final SummaryStatus status;
  final CourtAvailabilityModel? availability;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onRetry;

  const CourtScheduleSection({
    super.key,
    required this.days,
    required this.selectedDay,
    required this.status,
    required this.availability,
    required this.onDaySelected,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDayChips(context),
        const SizedBox(height: AppSpacing.md),
        _buildBody(),
      ],
    );
  }

  Widget _buildDayChips(BuildContext context) {
    final languageCode = context.locale.languageCode;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, index) {
          final day = days[index];
          return ChoiceChip(
            label: Text(DateFormatters.friendlyDay(day, languageCode)),
            selected: day == selectedDay,
            onSelected: (_) => onDaySelected(day),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    final loaded = availability;
    if (status == SummaryStatus.loading) return const SkeletonBox(height: 120);
    if (status == SummaryStatus.failed || loaded == null) return _buildError();
    final timeline = buildDayTimeline(loaded);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'mobile.courts.opening_hours'.tr(args: [loaded.opensAt, loaded.closesAt]),
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final entry in timeline) _TimelineRow(entry: entry),
        const SizedBox(height: AppSpacing.xs),
        Text('mobile.courts.schedule_note'.tr(), style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildError() => AppCard(
        child: Row(
          children: [
            Expanded(
              child: Text('mobile.courts.schedule_error'.tr(), style: AppTextStyles.bodyMuted),
            ),
            TextButton(onPressed: onRetry, child: Text('common.retry'.tr())),
          ],
        ),
      );
}

class _TimelineRow extends StatelessWidget {
  final DayTimelineEntry entry;

  const _TimelineRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isFree = entry.kind == DayTimelineKind.free;
    return AppCard(
      accent: isFree ? AppColors.success : AppColors.warning,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Icon(
            isFree ? Icons.check_circle_outline : Icons.event_busy_outlined,
            size: 20,
            color: isFree ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${DateFormatters.time(entry.startsAt)} – ${DateFormatters.time(entry.endsAt)}',
                  style: AppTextStyles.cardTitle,
                ),
                Text(_subtitle(), style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _subtitle() {
    if (entry.kind == DayTimelineKind.free) {
      return '${'mobile.courts.slot_free'.tr()} · ${formatSlotDuration(entry.duration)}';
    }
    return entry.matchTitle ?? 'mobile.courts.slot_busy'.tr();
  }
}
