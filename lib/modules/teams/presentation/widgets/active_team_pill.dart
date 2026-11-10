import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/teams/presentation/providers/active_team_notifier.dart';
import 'package:sport_platform/shared/widgets/initials_avatar.dart';
import 'package:sport_platform/shared/widgets/sheet_handle.dart';

/// Dice de qué equipo es lo que se ve en la pantalla y deja cambiarlo sin salir de ella. Va en las pantallas que dependen
/// del equipo activo (inicio, partidos, reportes, rankings); quien tiene un solo equipo no tiene nada que cambiar y no ve
/// nada.
class ActiveTeamPill extends StatelessWidget {
  /// Separación alrededor; solo se aplica cuando se dibuja, para que no deje un hueco en quien no lo ve.
  final EdgeInsetsGeometry margin;

  /// Solo para las pruebas; la app usa el de [getIt].
  final ActiveTeamNotifier? notifier;

  const ActiveTeamPill({super.key, this.margin = EdgeInsets.zero, this.notifier});

  @override
  Widget build(BuildContext context) {
    context.locale;
    final source = notifier ?? getIt<ActiveTeamNotifier>();
    return ListenableBuilder(
      listenable: source,
      builder: (context, _) {
        final team = source.activeTeam;
        if (!source.hasSeveralTeams || team == null) return const SizedBox.shrink();
        return Padding(
          padding: margin,
          child: Align(
            alignment: Alignment.centerLeft,
            child: _Pill(team: team, onTap: () => showTeamPickerSheet(context, source)),
          ),
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  final PlayerTeam team;
  final VoidCallback onTap;

  const _Pill({required this.team, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final crestColor = InitialsAvatar.colorOf(team.teamName);
    return Semantics(
      button: true,
      label: '${'mobile.teams.active_team_label'.tr()}: ${team.teamName}',
      child: ExcludeSemantics(
        child: Material(
          color: crestColor.withValues(alpha: 0.22),
          shape: StadiumBorder(side: BorderSide(color: crestColor.withValues(alpha: 0.8))),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSizes.touchTarget - 8),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InitialsAvatar(name: team.teamName, size: 28),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        team.teamName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(Icons.unfold_more_rounded, size: 18, color: AppColors.whiteSubtle),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Abre la hoja con los equipos del jugador; al elegir uno pasa a ser el activo de toda la app y la hoja se cierra.
Future<void> showTeamPickerSheet(BuildContext context, ActiveTeamNotifier notifier) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (_) => _TeamPickerSheet(notifier: notifier),
  );
}

class _TeamPickerSheet extends StatelessWidget {
  final ActiveTeamNotifier notifier;

  const _TeamPickerSheet({required this.notifier});

  @override
  Widget build(BuildContext context) {
    context.locale;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, AppSpacing.md, 0, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.sm),
              child: Text('mobile.teams.switch_title'.tr(), style: AppTextStyles.sectionTitle),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final team in notifier.teams)
                    ListTile(
                      key: ValueKey('team-option-${team.teamId}'),
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      leading: InitialsAvatar(name: team.teamName, size: 44),
                      title: Text(team.teamName, style: AppTextStyles.body.copyWith(fontSize: 16)),
                      subtitle: team.isCaptain
                          ? Text('mobile.teams.captain'.tr(), style: AppTextStyles.caption)
                          : null,
                      trailing: team.teamId == notifier.activeTeamId
                          ? const Icon(Icons.check_circle, color: AppColors.primaryLight)
                          : null,
                      onTap: () {
                        notifier.select(team.teamId);
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
