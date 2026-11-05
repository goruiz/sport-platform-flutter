import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/shared/widgets/app_card.dart';

/// Lo primero que ve quien aún no tiene equipo: sin equipo no hay partidos que mostrar, así que el inicio
/// le ofrece directamente lo único que puede hacer, escribir el código que le dio su administrador.
class JoinTeamCard extends StatelessWidget {
  final VoidCallback onJoin;

  const JoinTeamCard({super.key, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      accent: AppColors.primaryLight,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.groups_outlined, color: AppColors.primaryLight, size: 26),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text('mobile.teams.empty_title'.tr(), style: AppTextStyles.sectionTitle),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('join_team.home_hint'.tr(), style: AppTextStyles.bodyMuted),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onJoin,
              icon: const Icon(Icons.vpn_key_outlined, size: 20),
              label: Text('join_team.title'.tr()),
            ),
          ),
        ],
      ),
    );
  }
}
