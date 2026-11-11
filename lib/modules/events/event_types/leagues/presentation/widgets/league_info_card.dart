import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/utils/date_formatters.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/shared/widgets/info_row.dart';
import 'package:sport_platform/shared/widgets/status_badge.dart';

/// Los datos de un evento: nombre, estado, descripción, fechas, formato y tipo. Solo se leen: el organizador
/// los edita desde el panel.
class LeagueInfoCard extends StatelessWidget {
  final EventModel event;

  const LeagueInfoCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.name,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerLeft, child: StatusBadge.forEvent(event.status)),
          if (event.description != null && event.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              event.description!,
              style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 14),
            ),
          ],
          const SizedBox(height: 16),
          InfoRow(
            icon: Icons.calendar_today,
            title: 'leagues.info_dates'.tr(),
            label: DateFormatters.shortRange(
              event.startDate,
              event.endDate,
              context.locale.languageCode,
            ),
          ),
          if (event.format.isNotEmpty) ...[
            const SizedBox(height: 12),
            InfoRow(
              icon: Icons.format_list_bulleted,
              title: 'leagues.info_format'.tr(),
              label: event.format,
            ),
          ],
          if (event.eventTypeName != null && event.eventTypeName!.isNotEmpty) ...[
            const SizedBox(height: 12),
            InfoRow(
              icon: Icons.military_tech,
              title: 'leagues.info_type'.tr(),
              label: event.eventTypeName!,
            ),
          ],
        ],
      ),
    );
  }
}
