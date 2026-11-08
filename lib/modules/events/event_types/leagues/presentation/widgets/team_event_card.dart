import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/team_event_model.dart';
import 'package:sport_platform/shared/widgets/initials_avatar.dart';

class TeamEventCard extends StatelessWidget {
  final TeamEventModel team;
  final VoidCallback? onRemove;
  final VoidCallback? onManagePlayers;

  /// Abre el detalle del equipo en el evento (balance, partidos, goleadores…). Con él la tarjeta se puede tocar.
  final VoidCallback? onOpen;

  const TeamEventCard({
    super.key,
    required this.team,
    this.onRemove,
    this.onManagePlayers,
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
        onTap: onOpen ?? onManagePlayers,
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
                    if (onManagePlayers != null || onOpen != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        onOpen != null
                            ? 'leagues.team_detail.tap_hint'.tr()
                            : 'leagues.tap_to_manage_players'.tr(),
                        style: const TextStyle(
                          color: AppColors.whiteSubtle,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onManagePlayers != null)
                IconButton(
                  onPressed: onManagePlayers,
                  icon: const Icon(
                    Icons.manage_accounts_outlined,
                    color: AppColors.primaryLight,
                    size: 20,
                  ),
                  tooltip: 'leagues.manage_players'.tr(),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              if (onOpen != null && onManagePlayers == null && onRemove == null)
                const Icon(Icons.chevron_right, color: AppColors.whiteSubtle),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
                  tooltip: 'leagues.remove_team'.tr(),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
