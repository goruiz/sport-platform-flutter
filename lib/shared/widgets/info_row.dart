import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';

/// Un dato con su icono: un rótulo pequeño (opcional) y el valor debajo. El valor puede ocupar varias líneas.
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? title;

  const InfoRow({super.key, required this.icon, required this.label, this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryLight, size: 18),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) Text(title!, style: AppTextStyles.caption),
              Text(label, style: AppTextStyles.body),
            ],
          ),
        ),
      ],
    );
  }
}
