import 'package:flutter/material.dart';
import 'package:sport_platform/core/modules/module_registry.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';

class AppRouteFactory {
  /// Scaffold-free content widget for use inside HomePage's bottom nav body.
  static Widget tabForItem(MenuItemModel item) =>
      ModuleRegistry.buildTab(item);

  /// Pushes a full-scaffold page using the item's url.
  /// No-ops if the url is empty (item is purely a container).
  static void navigateTo(BuildContext context, MenuItemModel item) {
    if (item.url == null || item.url!.trim().isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ModuleRegistry.buildPage(item)),
    );
  }
}
