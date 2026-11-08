import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/shared/widgets/app_card.dart';

/// Un bloque del perfil con título: las filas van juntas en una sola tarjeta, separadas por una línea fina.
class ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const ProfileSection({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.sm),
          child: Text(title.toUpperCase(), style: AppTextStyles.overline),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Un dato de solo lectura: su nombre pequeño y el valor al lado. Un dato vacío se muestra con un guion.
class ProfileInfoRow extends StatelessWidget {
  final String label;
  final String? value;

  const ProfileInfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(label, style: AppTextStyles.caption)),
          Expanded(
            flex: 6,
            child: Text(
              hasValue ? value! : '—',
              textAlign: TextAlign.end,
              style: AppTextStyles.body.copyWith(
                color: hasValue ? AppColors.white : AppColors.whiteSubtle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Una fila de aviso dentro de un bloque del perfil: un texto y, si algo falló, el botón para reintentar.
class ProfileMessageRow extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ProfileMessageRow({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(child: Text(message, style: AppTextStyles.bodyMuted)),
          if (onRetry != null) TextButton(onPressed: onRetry, child: Text('common.retry'.tr())),
        ],
      ),
    );
  }
}
