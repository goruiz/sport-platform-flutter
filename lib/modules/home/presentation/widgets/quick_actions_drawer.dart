import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/core/constants/locale_keys.g.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/modules/menu_item_model.dart';
import 'package:sport_platform/modules/home/presentation/constants/menu_colors.dart';

class QuickActionsDrawer extends StatelessWidget {
  final List<MenuItemModel> items;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onRetry;
  final void Function(MenuItemModel item)? onNavigate;

  const QuickActionsDrawer({
    super.key,
    required this.items,
    required this.isLoading,
    required this.hasError,
    required this.onRetry,
    this.onNavigate,
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
                LocaleKeys.home_section_quick_actions.tr(),
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
        child: CircularProgressIndicator(),
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
              SizedBox(height: AppSpacing.sm),
              Text(
                'Error al cargar. Toca para reintentar.',
                style: AppTextStyles.secondary,
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
          style: AppTextStyles.secondary,
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
                item.localizedName,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: item.localizedDescription != null
                  ? Text(
                      item.localizedDescription!,
                      style: AppTextStyles.footnote,
                    )
                  : null,
              iconColor: color,
              collapsedIconColor: AppColors.whiteSubtle,
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.hairline),
              childrenPadding: EdgeInsets.zero,
              children: item.children.asMap().entries.map((entry) {
                final childColor = kMenuColors[entry.key % kMenuColors.length];
                final child = entry.value;
                return ListTile(
                  contentPadding: const EdgeInsets.only(
                      left: 80, right: AppSpacing.xl, top: AppSpacing.hairline, bottom: AppSpacing.hairline),
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
                    child.localizedName,
                    style: const TextStyle(color: AppColors.white, fontSize: 13),
                  ),
                  subtitle: child.localizedDescription != null
                      ? Text(
                          child.localizedDescription!,
                          style: AppTextStyles.micro,
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    onNavigate?.call(child);
                  },
                );
              }).toList(),
            ),
          );
        }

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xs),
          leading: leading,
          title: Text(
            item.localizedName,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: item.localizedDescription != null
              ? Text(
                  item.localizedDescription!,
                  style: AppTextStyles.footnote,
                )
              : null,
          onTap: () {
            Navigator.pop(context);
            onNavigate?.call(item);
          },
        );
      },
    );
  }
}
