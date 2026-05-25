import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';

class PlaceholderTab extends StatelessWidget {
  final MenuItemModel item;

  const PlaceholderTab({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final icon = MenuItemModel.iconFromString(item.icon);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryLight.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(icon, color: AppColors.primaryLight, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              item.displayName.tr(),
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Próximamente',
              style: TextStyle(color: AppColors.whiteSubtle, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
