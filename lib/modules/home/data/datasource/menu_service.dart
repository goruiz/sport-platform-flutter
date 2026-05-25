import 'dart:convert';

import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';

class MenuResult {
  final List<MenuItemModel> navItems;
  final List<MenuItemModel> menuItems;

  const MenuResult({
    required this.navItems,
    required this.menuItems,
  });
}

class MenuService {
  final DioClient _client = DioClient();

  Future<MenuResult> getMenu() async {
    final response = await _client.get(ApiEndpoints.menu);

    // Dio may return the body as a String when the server omits Content-Type: application/json
    final raw = response.data is String
        ? jsonDecode(response.data as String)
        : response.data;

    // Support both a plain list and a wrapped { "data": [...] } envelope
    final List<dynamic> data = raw is List ? raw : (raw as Map)['data'] as List<dynamic>;

    final all = data
        .map((e) => MenuItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // The API already returns a fully nested structure: submenus are embedded
    // inside each parent's "submenus" array. MenuItemModel.fromJson handles the
    // nesting recursively, so no manual tree-building is needed here.
    final navItems = all
        .where((i) => i.isNavItem)
        .toList()
      ..sort((a, b) => a.navOrder!.compareTo(b.navOrder!));

    final menuItems = all
        .where((i) => !i.isNavItem)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return MenuResult(navItems: navItems, menuItems: menuItems);
  }
}
