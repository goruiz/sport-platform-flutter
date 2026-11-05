import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';

/// El estado «aquí no hay nada todavía»: un icono, qué pasa, qué hacer y, si hay una acción posible, un botón.
/// Siempre debe decirle a la persona por qué está vacío y qué puede hacer: nunca una pantalla en blanco.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onAdd;

  /// El texto y el icono del botón de [onAdd]; sin ellos es «Crear» con un «+».
  final String? actionLabel;
  final IconData actionIcon;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onAdd,
    this.actionLabel,
    this.actionIcon = Icons.add,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl + AppSpacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryLight.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(icon, color: AppColors.primaryLight, size: 40),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(title, textAlign: TextAlign.center, style: AppTextStyles.pageTitle.copyWith(fontSize: 20)),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(subtitle, textAlign: TextAlign.center, style: AppTextStyles.bodyMuted),
            ],
            if (onAdd != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              FilledButton.icon(
                onPressed: onAdd,
                icon: Icon(actionIcon),
                label: Text(actionLabel ?? 'common.create'.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
