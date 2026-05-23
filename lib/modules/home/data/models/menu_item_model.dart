import 'package:flutter/material.dart';

class MenuItemModel {
  final String id;
  final String name;
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
    this.description,
    this.icon,
    this.url,
    this.order = 0,
    this.navOrder,
    this.idParentMenu,
    this.children = const [],
  });

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

  // Outlined variant for nav inactive state; falls back to filled when none exists
  static IconData iconOutlinedFromString(String? name) {
    switch (name) {
      case 'home':        return Icons.home_outlined;
      case 'leaderboard': return Icons.leaderboard_outlined;
      case 'person':      return Icons.person_outline;
      case 'group':       return Icons.group_outlined;
      case 'event':       return Icons.event_outlined;
      case 'notifications': return Icons.notifications_outlined;
      case 'settings':    return Icons.settings_outlined;
      case 'search':      return Icons.search_outlined;
      case 'star':        return Icons.star_outline;
      case 'flag':        return Icons.flag_outlined;
      case 'shield':      return Icons.shield_outlined;
      default:            return iconFromString(name);
    }
  }

  static IconData iconFromString(String? name) {
    switch (name) {
      case 'group_add': return Icons.group_add;
      case 'emoji_events': return Icons.emoji_events;
      case 'sports_soccer': return Icons.sports_soccer;
      case 'workspace_premium': return Icons.workspace_premium;
      case 'login': return Icons.login;
      case 'sports': return Icons.sports;
      case 'home': return Icons.home;
      case 'group': return Icons.group;
      case 'event': return Icons.event;
      case 'leaderboard': return Icons.leaderboard;
      case 'person': return Icons.person;
      case 'settings': return Icons.settings;
      case 'star': return Icons.star;
      case 'add': return Icons.add;
      case 'calendar_today': return Icons.calendar_today;
      case 'notifications': return Icons.notifications;
      case 'search': return Icons.search;
      case 'message': return Icons.message;
      case 'chat': return Icons.chat;
      case 'location_on': return Icons.location_on;
      case 'bar_chart': return Icons.bar_chart;
      case 'timeline': return Icons.timeline;
      case 'shield': return Icons.shield;
      case 'flag': return Icons.flag;
      case 'trophy': return Icons.emoji_events;
      case 'fitness_center': return Icons.fitness_center;
      case 'directions_run': return Icons.directions_run;
      case 'sports_basketball': return Icons.sports_basketball;
      case 'sports_tennis': return Icons.sports_tennis;
      case 'sports_volleyball': return Icons.sports_volleyball;
      default: return Icons.sports;
    }
  }
}
