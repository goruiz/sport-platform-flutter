import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/strings_constants/app_strings_constants.dart';
import 'package:sport_platform/core/constants/strings_constants/home_strings_constants.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/home/data/datasource/menu_service.dart';
import 'package:sport_platform/modules/home/presentation/enums/menu_style.dart';
import 'package:sport_platform/modules/home/presentation/widgets/home_tab.dart';
import 'package:sport_platform/modules/home/presentation/widgets/notification_bell.dart';
import 'package:sport_platform/modules/players/presentation/providers/invitations_notifier.dart';
import 'package:sport_platform/core/routes/app_route_factory.dart';
import 'package:sport_platform/modules/home/presentation/widgets/quick_actions_drawer.dart';
import 'package:sport_platform/shared/widgets/language_selector.dart';
import 'package:sport_platform/shared/widgets/logout_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  HomeMenuStyle _menuStyle = HomeMenuStyle.carousel;

  List<MenuItemModel> _navItems = [];
  List<MenuItemModel> _menuItems = [];
  bool _isLoadingMenu = true;
  bool _menuError = false;

  final _menuService = MenuService();

  @override
  void initState() {
    super.initState();
    _loadMenu();
    // La campana y la tarjeta de invitaciones del inicio leen este mismo estado.
    getIt<InvitationsNotifier>().load();
  }

  Future<void> _loadMenu() async {
    setState(() {
      _isLoadingMenu = true;
      _menuError = false;
    });
    try {
      final result = await _menuService.getMenu();
      if (!mounted) return;
      setState(() {
        _navItems = result.navItems;
        _menuItems = result.menuItems;
      });
    } catch (e, st) {
      debugPrint('MenuService error: $e\n$st');
      if (!mounted) return;
      setState(() => _menuError = true);
    } finally {
      if (mounted) setState(() => _isLoadingMenu = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Scaffold(
      backgroundColor: AppColors.backgroundEnd,
      appBar: _buildAppBar(),
      drawer: _menuStyle == HomeMenuStyle.drawer
          ? QuickActionsDrawer(
              items: _menuItems,
              isLoading: _isLoadingMenu,
              hasError: _menuError,
              onRetry: _loadMenu,
              onNavigate: (item) => AppRouteFactory.navigateTo(context, item),
            )
          : null,
      body: _buildTabBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTabBody() {
    if (_navItems.isEmpty && _isLoadingMenu) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryLight),
      );
    }
    if (_navItems.isEmpty && _menuError) {
      return Center(
        child: TextButton.icon(
          onPressed: _loadMenu,
          icon: const Icon(Icons.refresh, color: AppColors.primaryLight),
          label: Text(
            'common.retry'.tr(),
            style: const TextStyle(color: AppColors.primaryLight),
          ),
        ),
      );
    }
    if (_navItems.isEmpty) return const SizedBox.shrink();
    final safeIdx = _currentIndex.clamp(0, _navItems.length - 1);
    if (safeIdx == 0) {
      return HomeTab(
        menuStyle: _menuStyle,
        menuItems: _menuItems,
        isLoadingMenu: _isLoadingMenu,
        menuError: _menuError,
        onRetryMenu: _loadMenu,
        onNavigate: _navigateToUrl,
      );
    }

    return AppRouteFactory.tabForItem(_navItems[safeIdx]);
  }

  void _navigateToUrl(String url) {
    final item = _findMenuItem([..._navItems, ..._menuItems], url);
    if (item != null && mounted) {
      AppRouteFactory.navigateTo(context, item);
    }
  }

  MenuItemModel? _findMenuItem(List<MenuItemModel> items, String url) {
    for (final item in items) {
      if (item.url == url) return item;
      final nested = _findMenuItem(item.children, url);
      if (nested != null) return nested;
    }
    return null;
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryDark,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: _menuStyle == HomeMenuStyle.drawer
          ? Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, color: AppColors.white),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            )
          : null,
      title: Text(
        AppStringsConstants.appName.tr(),
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _menuStyle == HomeMenuStyle.carousel
                ? Icons.view_sidebar_outlined
                : Icons.view_carousel_outlined,
            color: AppColors.white,
          ),
          tooltip: _menuStyle == HomeMenuStyle.carousel
              ? HomeStringsConstants.switchToDrawer.tr()
              : HomeStringsConstants.switchToCarousel.tr(),
          onPressed: () => setState(() {
            _menuStyle = _menuStyle == HomeMenuStyle.carousel
                ? HomeMenuStyle.drawer
                : HomeMenuStyle.carousel;
          }),
        ),
        const LanguageSelector(),
        const NotificationBell(),
        const LogoutButton(),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBottomNav() {
    if (_navItems.length < 2) return const SizedBox.shrink();

    final safeIndex = _currentIndex.clamp(0, _navItems.length - 1);

    return BottomNavigationBar(
      currentIndex: safeIndex,
      onTap: (i) => setState(() => _currentIndex = i),
      backgroundColor: AppColors.primaryDark,
      selectedItemColor: AppColors.primaryLight,
      unselectedItemColor: AppColors.whiteSubtle,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle:
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      items: _navItems
          .map((item) => BottomNavigationBarItem(
                icon: Icon(MenuItemModel.iconOutlinedFromString(item.icon)),
                activeIcon: Icon(MenuItemModel.iconFromString(item.icon)),
                label: item.localizedName,
              ))
          .toList(),
    );
  }
}
