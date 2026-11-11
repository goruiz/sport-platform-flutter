import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/match_card.dart';

/// Los partidos de una jornada (un día), con su encabezado.
class MatchDaySection extends StatelessWidget {
  final int dayIndex;
  final DateTime date;
  final List<MatchModel> matches;
  final Map<String, String> teamMap;
  final void Function(MatchModel)? onOpen;

  const MatchDaySection({
    super.key,
    required this.dayIndex,
    required this.date,
    required this.matches,
    required this.teamMap,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DayHeader(dayIndex: dayIndex, date: date),
        ...matches.map((m) => MatchCard(
              match: m,
              homeTeamName: teamMap[m.homeTeamId] ?? m.homeTeamId,
              awayTeamName: teamMap[m.awayTeamId] ?? m.awayTeamId,
              onTap: onOpen == null ? null : () => onOpen!(m),
            )),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  final int dayIndex;
  final DateTime date;

  const _DayHeader({required this.dayIndex, required this.date});

  @override
  Widget build(BuildContext context) {
    final dayLabel = DateFormat(
      'EEE d MMM yyyy',
      context.locale.toString(),
    ).format(date);

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
              dayLabel,
              style: const TextStyle(
                color: AppColors.whiteSubtle,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
