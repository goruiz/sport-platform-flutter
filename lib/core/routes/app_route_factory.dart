import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/events/presentation/pages/events_page.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/home/presentation/widgets/placeholder_tab.dart';
import 'package:sport_platform/modules/matches/presentation/pages/matches_page.dart';
import 'package:sport_platform/modules/rankings/presentation/pages/rankings_page.dart';
import 'package:sport_platform/modules/reports/presentation/pages/reports_page.dart';
import 'package:sport_platform/modules/teams/presentation/pages/teams_page.dart';
import 'package:sport_platform/modules/users/presentation/pages/profile_page.dart';

class AppRouteFactory {
  /// Scaffold-free content widget for use inside HomePage's bottom nav body.
  static Widget tabForItem(MenuItemModel item) {
    return PlaceholderTab(item: item);
  }

  /// Pushes a full-scaffold page using the item's url.
  /// No-ops if the url is empty (item is purely a container).
  static void navigateTo(BuildContext context, MenuItemModel item) {
    if (item.url == null || item.url!.trim().isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _pageForItem(item)),
    );
  }

  static Widget _pageForItem(MenuItemModel item) {
    switch (_normalize(item.url)) {
      case '/teams':
        return TeamsPage(item: item);
      case '/events':
        return EventsPage(item: item);
      case '/rankings':
        return RankingsPage(item: item);
      case '/matches':
        return MatchesPage(item: item);
      case '/reports':
        return ReportsPage(item: item);
      case '/profile':
        return ProfilePage(item: item);
      default:
        return _GenericModulePage(item: item);
    }
  }

  static String _normalize(String? url) {
    if (url == null || url.isEmpty) return '';
    final s = url.trim().toLowerCase();
    return s.startsWith('/') ? s : '/$s';
  }
}

/// Fallback full-scaffold page for URLs not yet registered in AppRouteFactory.
class _GenericModulePage extends StatelessWidget {
  final MenuItemModel item;
  const _GenericModulePage({required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundEnd,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: Text(item.name, style: const TextStyle(color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: PlaceholderTab(item: item),
    );
  }
}
