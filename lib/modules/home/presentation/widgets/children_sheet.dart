import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/home/presentation/constants/menu_colors.dart';

class ChildrenSheet extends StatelessWidget {
  final MenuItemModel parent;
  final Color parentColor;

  const ChildrenSheet({
    super.key,
    required this.parent,
    required this.parentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
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
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
                const SizedBox(width: 10),
                Text(
                  parent.name,
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
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: parent.children.length,
            itemBuilder: (_, i) {
              final child = parent.children[i];
              final color = kMenuColors[i % kMenuColors.length];
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
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
                  child.name,
                  style: const TextStyle(color: AppColors.white, fontSize: 14),
                ),
                subtitle: child.description != null && child.description!.isNotEmpty
                    ? Text(
                        child.description!,
                        style:
                            const TextStyle(color: AppColors.whiteSubtle, fontSize: 12),
                      )
                    : null,
                onTap: () => Navigator.pop(context),
              );
            },
          ),
        ],
      ),
    );
  }
}
