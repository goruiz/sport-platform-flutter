import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/network/json_reader.dart';

class MenuItemModel {
  final String id;
  final String name;
  final String? translationKey;
  final String? description;
  final String? descriptionTranslationKey;
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
    this.descriptionTranslationKey,
    this.icon,
    this.url,
    this.order = 0,
    this.navOrder,
    this.idParentMenu,
    this.children = const [],
  });

  /// The name in the app's language: the dictionary's text for [translationKey], or the [name] the database stores
  /// when there is no key or the dictionary does not have it.
  String get localizedName => _translateOr(translationKey, name);

  /// The description in the app's language, resolved like [localizedName]; null when the item has none.
  String? get localizedDescription {
    final text = _translateOr(descriptionTranslationKey, description ?? '');
    return text.isEmpty ? null : text;
  }

  /// `tr()` answers the key itself when the dictionary does not know it, which would show "menu.something" on screen.
  static String _translateOr(String? key, String fallback) {
    if (key == null || key.isEmpty) return fallback;
    final translated = key.tr();
    return translated == key ? fallback : translated;
  }

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, resource: 'opción del menú');
    // Handles both nested (submenus/children arrays) and flat (id_parent_menu) responses
    final submenus = reader.list('submenus', MenuItemModel.fromJson);
    final children = [...(submenus.isNotEmpty ? submenus : reader.list('children', MenuItemModel.fromJson))]
      ..sort((a, b) => a.order.compareTo(b.order));

    return MenuItemModel(
      id: reader.requiredString('id'),
      // El nombre propio puede faltar en una opción que solo trae su clave de traducción.
      name: reader.textOrEmpty('name'),
      translationKey: reader.optionalString('translationKey'),
      description: reader.optionalString('description'),
      descriptionTranslationKey: reader.optionalString('descriptionTranslationKey'),
      icon: reader.optionalString('icon'),
      url: reader.optionalString('url'),
      // Una opción sin posición va al principio: el backend las manda siempre, es solo por si falta.
      order: reader.optionalInt('order') ?? 0,
      navOrder: reader.optionalInt('navOrder'),
      idParentMenu: reader.optionalString('idParentMenu'),
      children: children,
    );
  }

  MenuItemModel copyWith({List<MenuItemModel>? children}) => MenuItemModel(
        id: id,
        name: name,
        translationKey: translationKey,
        description: description,
        descriptionTranslationKey: descriptionTranslationKey,
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
    // Icons the backend shares with the Angular panel, which names them after CoreUI.
    'cilSoccer':         Icons.sports_soccer,
    'cilGroup':          Icons.groups,
    'cilHouse':          Icons.stadium,
    'cilShieldAlt':      Icons.shield,
    'cilCalendar':       Icons.event,
    'cilLocationPin':    Icons.location_on,
    'cilMap':            Icons.map,
    'cilMobile':         Icons.smartphone,
    'cilChart':          Icons.bar_chart,
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
