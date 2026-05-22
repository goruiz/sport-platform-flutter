import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/strings_constants/app_strings_constants.dart';
import 'package:sport_platform/core/constants/strings_constants/home_strings_constants.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/home/data/services/menu_service.dart';
import 'package:sport_platform/modules/home/presentation/enums/menu_style.dart';
import 'package:sport_platform/modules/home/presentation/widgets/home_tab.dart';
import 'package:sport_platform/modules/home/presentation/widgets/placeholder_tab.dart';
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

  List<MenuItemModel> _menuItems = [];
  bool _isLoadingMenu = true;
  bool _menuError = false;

  final _menuService = MenuService();

  static const _tabIcons = [
    Icons.home_outlined,
    Icons.group_outlined,
    Icons.event_outlined,
    Icons.leaderboard_outlined,
    Icons.person_outline,
  ];
  static const _tabActiveIcons = [
    Icons.home,
    Icons.group,
    Icons.event,
    Icons.leaderboard,
    Icons.person,
  ];

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() {
      _isLoadingMenu = true;
      _menuError = false;
    });
    try {
      final items = await _menuService.getMenu();
      if (!mounted) return;
      setState(() => _menuItems = items);
    } catch (_) {
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
            )
          : null,
      body: _currentIndex == 0
          ? HomeTab(
              menuStyle: _menuStyle,
              menuItems: _menuItems,
              isLoadingMenu: _isLoadingMenu,
              menuError: _menuError,
              onRetryMenu: _loadMenu,
            )
          : PlaceholderTab(index: _currentIndex),
      bottomNavigationBar: _buildBottomNav(),
    );
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
        const IconButton(
          icon: Icon(Icons.notifications_outlined, color: AppColors.white),
          onPressed: null,
        ),
        const LogoutButton(),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBottomNav() {
    final labels = [
      HomeStringsConstants.navHome.tr(),
      HomeStringsConstants.navTeams.tr(),
      HomeStringsConstants.navEvents.tr(),
      HomeStringsConstants.navRankings.tr(),
      HomeStringsConstants.navProfile.tr(),
    ];

    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (i) => setState(() => _currentIndex = i),
      backgroundColor: AppColors.primaryDark,
      selectedItemColor: AppColors.primaryLight,
      unselectedItemColor: AppColors.whiteSubtle,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle:
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      items: List.generate(
        5,
        (i) => BottomNavigationBarItem(
          icon: Icon(_tabIcons[i]),
          activeIcon: Icon(_tabActiveIcons[i]),
          label: labels[i],
        ),
      ),
    );
  }
}
