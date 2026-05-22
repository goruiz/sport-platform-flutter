import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/strings_constants/home_strings_constants.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/home/presentation/constants/menu_colors.dart';

class QuickActionsDrawer extends StatelessWidget {
  final List<MenuItemModel> items;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onRetry;

  const QuickActionsDrawer({
    super.key,
    required this.items,
    required this.isLoading,
    required this.hasError,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Drawer(
      backgroundColor: AppColors.primaryDark,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primaryDark,
              border: Border(bottom: BorderSide(color: AppColors.inputBorder)),
            ),
            margin: EdgeInsets.zero,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                HomeStringsConstants.sectionQuickActions.tr(),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryLight),
      );
    }
    if (hasError) {
      return Center(
        child: GestureDetector(
          onTap: onRetry,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh, color: AppColors.primaryLight, size: 32),
              SizedBox(height: 8),
              Text(
                'Error al cargar. Toca para reintentar.',
                style: TextStyle(color: AppColors.whiteSubtle, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Sin acciones disponibles',
          style: TextStyle(color: AppColors.whiteSubtle, fontSize: 13),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final color = kMenuColors[i % kMenuColors.length];
        final leading = Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(MenuItemModel.iconFromString(item.icon), color: color, size: 22),
        );

        if (item.hasChildren) {
          return Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              splashColor: color.withValues(alpha: 0.1),
            ),
            child: ExpansionTile(
              leading: leading,
              title: Text(
                item.name,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: item.description != null && item.description!.isNotEmpty
                  ? Text(
                      item.description!,
                      style:
                          const TextStyle(color: AppColors.whiteSubtle, fontSize: 12),
                    )
                  : null,
              iconColor: color,
              collapsedIconColor: AppColors.whiteSubtle,
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              childrenPadding: EdgeInsets.zero,
              children: item.children.asMap().entries.map((entry) {
                final childColor = kMenuColors[entry.key % kMenuColors.length];
                final child = entry.value;
                return ListTile(
                  contentPadding: const EdgeInsets.only(
                      left: 80, right: 20, top: 2, bottom: 2),
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: childColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      MenuItemModel.iconFromString(child.icon),
                      color: childColor,
                      size: 16,
                    ),
                  ),
                  title: Text(
                    child.name,
                    style:
                        const TextStyle(color: AppColors.white, fontSize: 13),
                  ),
                  subtitle: child.description != null &&
                          child.description!.isNotEmpty
                      ? Text(
                          child.description!,
                          style: const TextStyle(
                              color: AppColors.whiteSubtle, fontSize: 11),
                        )
                      : null,
                  onTap: () => Navigator.pop(context),
                );
              }).toList(),
            ),
          );
        }

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: leading,
          title: Text(
            item.name,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: item.description != null && item.description!.isNotEmpty
              ? Text(
                  item.description!,
                  style:
                      const TextStyle(color: AppColors.whiteSubtle, fontSize: 12),
                )
              : null,
          onTap: () => Navigator.pop(context),
        );
      },
    );
  }
}
