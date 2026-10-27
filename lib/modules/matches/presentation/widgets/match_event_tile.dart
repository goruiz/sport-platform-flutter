import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/matches/data/models/match_event_model.dart';

/// Una línea de la cronología: minuto, qué pasó, quién y de qué equipo.
class MatchEventTile extends StatelessWidget {
  final MatchEventModel event;
  final String teamName;

  const MatchEventTile({super.key, required this.event, required this.teamName});

  @override
  Widget build(BuildContext context) {
    final type = event.type;
    final color = type?.color ?? AppColors.whiteSubtle;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              event.minute == null ? '–' : "${event.minute}'",
              style: const TextStyle(
                color: AppColors.whiteSubtle,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(type?.icon ?? Icons.help_outline, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.playerName ?? 'match_detail.unknown_player'.tr(),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${type == null ? '' : '${type.translationKey.tr()} · '}$teamName',
                  style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
