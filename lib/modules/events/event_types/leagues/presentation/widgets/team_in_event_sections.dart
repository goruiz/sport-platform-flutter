import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/rankings/data/models/player_stats_model.dart';
import 'package:sport_platform/shared/widgets/app_card.dart';
import 'package:sport_platform/shared/widgets/initials_avatar.dart';

/// Un título de sección de la pantalla de un equipo en un evento.
class TeamInEventSectionTitle extends StatelessWidget {
  final String text;

  const TeamInEventSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.md),
        child: Text(text, style: AppTextStyles.sectionTitle),
      );
}

/// Un aviso dentro de una sección: no hay nada que mostrar o la lectura falló (con «Reintentar» si hay [onRetry]).
class TeamInEventMessage extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const TeamInEventMessage({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) => AppCard(
        child: Row(
          children: [
            Expanded(child: Text(message, style: AppTextStyles.bodyMuted)),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: Text('common.retry'.tr())),
          ],
        ),
      );
}

/// Los goleadores del equipo en el evento, de más a menos goles.
class TeamScorersList extends StatelessWidget {
  final List<PlayerStatsModel> scorers;

  const TeamScorersList({super.key, required this.scorers});

  @override
  Widget build(BuildContext context) {
    context.locale;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.lg),
      child: Column(
        children: [
          for (final (index, player) in scorers.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${index + 1}',
                      style: AppTextStyles.cardTitle.copyWith(color: AppColors.whiteSubtle),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      player.playerName ?? 'match_detail.unknown_player'.tr(),
                      style: AppTextStyles.body,
                    ),
                  ),
                  Text(
                    '${player.goals}',
                    style: AppTextStyles.cardTitle.copyWith(color: AppColors.primaryLight, fontSize: 18),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// La plantilla del equipo, con su capitán primero (quien llama ya los ordenó).
class TeamRosterList extends StatelessWidget {
  final List<PlayerModel> players;

  const TeamRosterList({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
    context.locale;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.lg),
      child: Column(
        children: [
          for (final player in players)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  InitialsAvatar(name: player.fullName, logoUrl: player.profilePhotoUrl, size: 36),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(player.fullName, style: AppTextStyles.body)),
                  if (player.isCaptain)
                    Text('mobile.teams.captain'.tr(), style: AppTextStyles.overline),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
