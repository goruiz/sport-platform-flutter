import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/modules/menu_item_model.dart';
import 'package:sport_platform/modules/home/presentation/constants/menu_colors.dart';

class ChildrenSheet extends StatelessWidget {
  final MenuItemModel parent;
  final Color parentColor;
  final void Function(MenuItemModel item)? onNavigate;

  const ChildrenSheet({
    super.key,
    required this.parent,
    required this.parentColor,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.md, 0, AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.whiteSubtle.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: parentColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    MenuItemModel.iconFromString(parent.icon),
                    color: parentColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.snug),
                Text(
                  parent.localizedName,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.inputBorder, height: 24),
          Flexible(
            child: ListView.builder(
              itemCount: parent.children.length,
              itemBuilder: (_, i) {
                final child = parent.children[i];
                final color = kMenuColors[i % kMenuColors.length];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.hairline),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      MenuItemModel.iconFromString(child.icon),
                      color: color,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    child.localizedName,
                    style: AppTextStyles.body,
                  ),
                  subtitle: child.localizedDescription != null
                      ? Text(
                          child.localizedDescription!,
                          style: AppTextStyles.footnote,
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    onNavigate?.call(child);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
