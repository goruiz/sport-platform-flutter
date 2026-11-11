import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/team_event_model.dart';
import 'package:sport_platform/shared/widgets/initials_avatar.dart';

class TeamEventCard extends StatelessWidget {
  final TeamEventModel team;

  /// Abre el detalle del equipo en el evento (balance, partidos, goleadores…). Con él la tarjeta se puede tocar.
  final VoidCallback? onOpen;

  const TeamEventCard({
    super.key,
    required this.team,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              InitialsAvatar(name: team.teamName, size: 42),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.teamName,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (onOpen != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'leagues.team_detail.tap_hint'.tr(),
                        style: const TextStyle(
                          color: AppColors.whiteSubtle,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onOpen != null)
                const Icon(Icons.chevron_right, color: AppColors.whiteSubtle),
            ],
          ),
        ),
      ),
    );
  }
}
