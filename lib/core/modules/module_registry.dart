import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/home/presentation/widgets/placeholder_tab.dart';

class ModuleRegistry {
  ModuleRegistry._();

  static final Map<String, Widget Function(MenuItemModel)> _builders = {};

  /// Registers a widget builder for a given URL path.
  /// Call this once per module from modules_setup.dart.
  static void register(String url, Widget Function(MenuItemModel) builder) {
    _builders[_normalize(url)] = builder;
  }

  /// Returns the scaffold-free content widget for use inside the bottom nav body.
  /// Falls back to PlaceholderTab for unregistered URLs.
  static Widget buildTab(MenuItemModel item) {
    final builder = _builders[_normalize(item.url)];
    return builder?.call(item) ?? PlaceholderTab(item: item);
  }

  /// Returns the full page widget for push navigation.
  /// Falls back to a generic scaffold page for unregistered URLs.
  static Widget buildPage(MenuItemModel item) {
    final builder = _builders[_normalize(item.url)];
    if (builder != null) return builder(item);
    return _GenericModulePage(item: item);
  }

  static String _normalize(String? url) {
    if (url == null || url.isEmpty) return '';
    final s = url.trim().toLowerCase();
    return s.startsWith('/') ? s : '/$s';
  }
}

class _GenericModulePage extends StatelessWidget {
  final MenuItemModel item;
  const _GenericModulePage({required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundEnd,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: Text(
          item.displayName.tr(),
          style: const TextStyle(color: AppColors.white),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: PlaceholderTab(item: item),
    );
  }
}
