import 'package:flutter/material.dart';

class MenuItemModel {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final String? url;
  final int order;
  final List<MenuItemModel> children;

  const MenuItemModel({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.url,
    this.order = 0,
    this.children = const [],
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    // La API usa "submenus" en los padres y "children" en los hijos
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
        children: children ?? this.children,
      );

  bool get hasChildren => children.isNotEmpty;

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
