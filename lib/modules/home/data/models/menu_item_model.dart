import 'package:flutter/material.dart';

class MenuItemModel {
  final String id;
  final String name;
  final String? translationKey;
  final String? description;
  final String? icon;
  final String? url;
  final int order;
  final int? navOrder;
  final String? idParentMenu;
  final List<MenuItemModel> children;

  const MenuItemModel({
    required this.id,
    required this.name,
    this.translationKey,
    this.description,
    this.icon,
    this.url,
    this.order = 0,
    this.navOrder,
    this.idParentMenu,
    this.children = const [],
  });

  /// Returns the translation key when available, otherwise the raw name.
  /// Call .tr() on this value to get the localized string.
  String get displayName => translationKey ?? name;

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    // Handles both nested (submenus/children arrays) and flat (id_parent_menu) responses
    final rawChildren = (json['submenus'] as List<dynamic>?)
        ?? (json['children'] as List<dynamic>?)
        ?? [];

    final children = rawChildren
        .map((e) => MenuItemModel.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return MenuItemModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      translationKey: json['translationKey'] as String?,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      url: json['url'] as String?,
      order: (json['order'] as num?)?.toInt() ?? 0,
      navOrder: (json['navOrder'] as num?)?.toInt(),
      idParentMenu: json['idParentMenu'] as String?,
      children: children,
    );
  }

  MenuItemModel copyWith({List<MenuItemModel>? children}) => MenuItemModel(
        id: id,
        name: name,
        translationKey: translationKey,
        description: description,
        icon: icon,
        url: url,
        order: order,
        navOrder: navOrder,
        idParentMenu: idParentMenu,
        children: children ?? this.children,
      );

  bool get hasChildren => children.isNotEmpty;
  bool get isNavItem   => navOrder != null && navOrder! > 0;
  bool get isTopLevel  => idParentMenu == null;

  static const Map<String, IconData> _filledIcons = {
    'home':              Icons.home,
    'leaderboard':       Icons.leaderboard,
    'person':            Icons.person,
    'group':             Icons.group,
    'group_add':         Icons.group_add,
    'event':             Icons.event,
    'emoji_events':      Icons.emoji_events,
    'trophy':            Icons.emoji_events,
    'military_tech':     Icons.military_tech,
    'notifications':     Icons.notifications,
    'settings':          Icons.settings,
    'search':            Icons.search,
    'star':              Icons.star,
    'add':               Icons.add,
    'flag':              Icons.flag,
    'shield':            Icons.shield,
    'message':           Icons.message,
    'chat':              Icons.chat,
    'location_on':       Icons.location_on,
    'bar_chart':         Icons.bar_chart,
    'timeline':          Icons.timeline,
    'calendar_today':    Icons.calendar_today,
    'fitness_center':    Icons.fitness_center,
    'directions_run':    Icons.directions_run,
    'login':             Icons.login,
    'workspace_premium': Icons.workspace_premium,
    'sports':            Icons.sports,
    'sports_soccer':     Icons.sports_soccer,
    'sports_basketball': Icons.sports_basketball,
    'sports_tennis':     Icons.sports_tennis,
    'sports_volleyball': Icons.sports_volleyball,
  };

  static const Map<String, IconData> _outlinedIcons = {
    'home':          Icons.home_outlined,
    'leaderboard':   Icons.leaderboard_outlined,
    'person':        Icons.person_outline,
    'group':         Icons.group_outlined,
    'event':         Icons.event_outlined,
    'notifications': Icons.notifications_outlined,
    'settings':      Icons.settings_outlined,
    'search':        Icons.search_outlined,
    'star':          Icons.star_outline,
    'flag':          Icons.flag_outlined,
    'shield':        Icons.shield_outlined,
    'military_tech': Icons.military_tech_outlined,
  };

  static IconData iconFromString(String? name) =>
      _filledIcons[name] ?? Icons.sports;

  static IconData iconOutlinedFromString(String? name) =>
      _outlinedIcons[name] ?? iconFromString(name);
}
