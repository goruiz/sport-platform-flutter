import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/shared/widgets/initials_avatar.dart';

/// Lo que el selector muestra de cada equipo.
class TeamSwitcherItem {
  final String teamId;
  final String name;
  final String? logoUrl;
  final int playerCount;

  /// Si el jugador es capitán de ESTE equipo (puede serlo de uno y de otro no).
  final bool isCaptain;

  const TeamSwitcherItem({
    required this.teamId,
    required this.name,
    this.logoUrl,
    required this.playerCount,
    required this.isCaptain,
  });
}

/// La tarjeta de un equipo en el selector: su escudo, su nombre y cuántos juegan en él, teñida con el color de su escudo
/// (el mismo que lleva en el resto de la app). La del equipo elegido brilla y tiene el borde de su color; mientras se
/// desliza, la que va entrando se ve más pequeña y apagada.
class TeamSwitcherCard extends StatelessWidget {
  static const double height = 112;

  /// Aire alrededor de la tarjeta para el resplandor de la elegida.
  static const double glowMargin = 10;

  static const Duration _animationDuration = Duration(milliseconds: 280);

  final TeamSwitcherItem item;
  final bool isSelected;

  const TeamSwitcherCard({super.key, required this.item, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    context.locale;
    final crestColor = InitialsAvatar.colorOf(item.name);
    return Semantics(
      selected: isSelected,
      child: AnimatedScale(
        scale: isSelected ? 1 : 0.95,
        duration: _animationDuration,
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: isSelected ? 1 : 0.65,
          duration: _animationDuration,
          child: AnimatedContainer(
            duration: _animationDuration,
            curve: Curves.easeOutCubic,
            height: height,
            decoration: _decoration(crestColor),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                _CrestWithCaptainStar(item: item),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: _Texts(item: item)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _decoration(Color crestColor) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          crestColor.withValues(alpha: isSelected ? 0.55 : 0.30),
          crestColor.withValues(alpha: isSelected ? 0.20 : 0.10),
        ],
      ),
      border: Border.all(
        color: isSelected ? crestColor.withValues(alpha: 0.95) : AppColors.inputBorder,
        width: isSelected ? 1.6 : 1,
      ),
      boxShadow: isSelected
          ? [BoxShadow(color: crestColor.withValues(alpha: 0.45), blurRadius: 18, offset: const Offset(0, 6))]
          : const [],
    );
  }
}

/// El escudo del equipo y, si el jugador es su capitán, una estrella en la esquina: se ve de un vistazo sin gastar texto.
class _CrestWithCaptainStar extends StatelessWidget {
  final TeamSwitcherItem item;

  const _CrestWithCaptainStar({required this.item});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InitialsAvatar(name: item.name, logoUrl: item.logoUrl, size: 64),
        if (item.isCaptain)
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.warning,
                border: Border.all(color: AppColors.primaryDark, width: 2),
              ),
              child: const Icon(Icons.star_rounded, size: 15, color: AppColors.primaryDark),
            ),
          ),
      ],
    );
  }
}

class _Texts extends StatelessWidget {
  final TeamSwitcherItem item;

  const _Texts({required this.item});

  @override
  Widget build(BuildContext context) {
    final count = 'mobile.teams.players_count'.tr(namedArgs: {'count': '${item.playerCount}'});
    final caption = item.isCaptain ? '$count · ${'mobile.teams.captain'.tr()}' : count;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.pageTitle.copyWith(fontSize: 19, height: 1.15),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption),
      ],
    );
  }
}
