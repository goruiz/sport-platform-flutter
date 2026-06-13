import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/utils/date_formatters.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/match_card.dart';
import 'package:sport_platform/shared/widgets/confirmation_dialog.dart';

class MatchDaySection extends StatelessWidget {
  final int dayIndex;
  final DateTime date;
  final List<MatchModel> matches;
  final Map<String, String> teamMap;
  final bool isOwner;
  final void Function(MatchModel) onEdit;
  final void Function(MatchModel) onDelete;
  final Future<void> Function(DateTime fromDate, DateTime? toDate) onRescheduleDay;

  const MatchDaySection({
    super.key,
    required this.dayIndex,
    required this.date,
    required this.matches,
    required this.teamMap,
    required this.isOwner,
    required this.onEdit,
    required this.onDelete,
    required this.onRescheduleDay,
  });

  Future<void> _handlePostpone(BuildContext context) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'leagues.match_day_postpone'.tr(),
      content: 'leagues.match_day_confirm_postpone'
          .tr(namedArgs: {'date': DateFormatters.date(date)}),
      confirmLabel: 'leagues.match_day_postpone_confirm'.tr(),
      cancelLabel: 'leagues.cancel'.tr(),
    );
    if (!confirmed) return;
    await onRescheduleDay(date, null);
  }

  Future<void> _handleReschedule(BuildContext context) async {
    final newDate = await showDatePicker(
      context: context,
      initialDate: date.add(const Duration(days: 7)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'leagues.match_day_pick_date'.tr(),
    );
    if (newDate == null || !context.mounted) return;

    final confirmed = await showConfirmationDialog(
      context,
      title: 'leagues.match_day_reschedule'.tr(),
      content: 'leagues.match_day_confirm_reschedule'.tr(namedArgs: {
        'from': DateFormatters.date(date),
        'to': DateFormatters.date(newDate),
      }),
      confirmLabel: 'leagues.match_day_reschedule_confirm'.tr(),
      cancelLabel: 'leagues.cancel'.tr(),
    );
    if (!confirmed || !context.mounted) return;
    await onRescheduleDay(date, newDate);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DayHeader(
          dayIndex: dayIndex,
          date: date,
          isOwner: isOwner,
          onPostpone: () => _handlePostpone(context),
          onReschedule: () => _handleReschedule(context),
        ),
        ...matches.map((m) => MatchCard(
              match: m,
              homeTeamName: teamMap[m.homeTeamId] ?? m.homeTeamId,
              awayTeamName: teamMap[m.awayTeamId] ?? m.awayTeamId,
              onEdit: isOwner ? () => onEdit(m) : null,
              onDelete: isOwner ? () => onDelete(m) : null,
            )),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  final int dayIndex;
  final DateTime date;
  final bool isOwner;
  final VoidCallback onPostpone;
  final VoidCallback onReschedule;

  const _DayHeader({
    required this.dayIndex,
    required this.date,
    required this.isOwner,
    required this.onPostpone,
    required this.onReschedule,
  });

  String get _dayLabel {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final dow = days[date.weekday - 1];
    return '$dow ${date.day} ${_monthAbbr(date.month)} ${date.year}';
  }

  static String _monthAbbr(int m) {
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return months[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4)),
            ),
            child: Text(
              'leagues.match_day_label'
                  .tr(namedArgs: {'n': dayIndex.toString()}),
              style: const TextStyle(
                color: AppColors.primaryLight,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _dayLabel,
              style: const TextStyle(
                color: AppColors.whiteSubtle,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (isOwner)
            PopupMenuButton<_DayAction>(
              onSelected: (action) {
                if (action == _DayAction.postpone) {
                  onPostpone();
                } else {
                  onReschedule();
                }
              },
              color: AppColors.sheetBackground,
              icon: const Icon(Icons.more_vert,
                  color: AppColors.whiteSubtle, size: 20),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _DayAction.reschedule,
                  child: Row(
                    children: [
                      const Icon(Icons.edit_calendar_outlined,
                          color: AppColors.primaryLight, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'leagues.match_day_reschedule'.tr(),
                        style: const TextStyle(color: AppColors.white),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: _DayAction.postpone,
                  child: Row(
                    children: [
                      const Icon(Icons.pause_circle_outline,
                          color: Color(0xFFFFB347), size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'leagues.match_day_postpone'.tr(),
                        style: const TextStyle(color: AppColors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

enum _DayAction { reschedule, postpone }
