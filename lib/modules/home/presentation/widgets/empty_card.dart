import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/core/theme/app_colors.dart';

class EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;

  const EmptyCard({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.whiteSubtle, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: AppTextStyles.secondary,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.hairline),
                  Text(
                    subtitle!,
                    style: AppTextStyles.micro,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
