import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/constants/locale_keys.g.dart';
import 'package:sport_platform/core/theme/app_colors.dart';

class DrawerHintCard extends StatelessWidget {
  final VoidCallback onTap;

  const DrawerHintCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.menu, color: AppColors.primaryLight, size: 24),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                LocaleKeys.home_open_side_menu.tr(),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.whiteSubtle, size: 20),
          ],
        ),
      ),
    );
  }
}
