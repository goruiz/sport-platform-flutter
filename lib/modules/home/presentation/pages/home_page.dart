import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/strings_constants/app_strings_constants.dart';
import 'package:sport_platform/core/constants/strings_constants/home_strings_constants.dart';
import 'package:sport_platform/core/constants/strings_constants/logout_strings_constants.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/home/data/datasource/menu_service.dart';
import 'package:sport_platform/modules/home/presentation/enums/menu_style.dart';
import 'package:sport_platform/modules/home/presentation/widgets/home_tab.dart';
import 'package:sport_platform/modules/home/presentation/widgets/notification_bell.dart';
import 'package:sport_platform/modules/players/presentation/providers/invitations_notifier.dart';
import 'package:sport_platform/modules/users/presentation/providers/email_verification_notifier.dart';
import 'package:sport_platform/core/routes/app_route_factory.dart';
import 'package:sport_platform/modules/home/presentation/widgets/quick_actions_drawer.dart';
import 'package:sport_platform/shared/widgets/error_retry.dart';
import 'package:sport_platform/shared/widgets/language_sheet.dart';
import 'package:sport_platform/shared/widgets/logout_flow.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  HomeMenuStyle _menuStyle = HomeMenuStyle.grid;

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
    // El aviso de «confirma tu correo» solo sale si el backend dice que aún no lo está.
    getIt<EmailVerificationNotifier>().load();
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
      // Las demás pestañas (Equipos, Eventos, Perfil) traen su propia barra con su título: dos barras seguidas
      // gastarían espacio y confundirían.
      appBar: _isOnHomeTab ? _buildAppBar() : null,
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

  bool get _isOnHomeTab =>
      _navItems.isEmpty || _currentIndex.clamp(0, _navItems.length - 1) == 0;

  Widget _buildTabBody() {
    if (_navItems.isEmpty && _isLoadingMenu) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryLight),
      );
    }
    if (_navItems.isEmpty && _menuError) {
      return ErrorRetry(
        message: HomeStringsConstants.menuError.tr(),
        onRetry: _loadMenu,
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
        onToggleMenuStyle: _toggleMenuStyle,
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

  void _toggleMenuStyle() {
    setState(() {
      _menuStyle = _menuStyle == HomeMenuStyle.grid
          ? HomeMenuStyle.drawer
          : HomeMenuStyle.grid;
    });
  }

  /// La barra superior solo lleva lo que se usa a diario: el nombre de la app y la campana de invitaciones.
  /// El idioma y cerrar sesión van en un menú aparte (y también en el perfil), para que un toque sin querer no cierre la sesión.
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: _menuStyle == HomeMenuStyle.drawer
          ? Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu),
                tooltip: HomeStringsConstants.openSideMenu.tr(),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            )
          : null,
      title: Text(AppStringsConstants.appName.tr()),
      actions: [
        const NotificationBell(),
        _buildAccountMenu(),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildAccountMenu() {
    return PopupMenuButton<_AccountMenuAction>(
      tooltip: 'common.more_options'.tr(),
      icon: const Icon(Icons.more_vert),
      onSelected: (action) => switch (action) {
        _AccountMenuAction.language => showLanguageSheet(context),
        _AccountMenuAction.logout => confirmAndLogOut(context),
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _AccountMenuAction.language,
          child: _AccountMenuRow(icon: Icons.language, label: 'mobile.profile.language'.tr()),
        ),
        PopupMenuItem(
          value: _AccountMenuAction.logout,
          child: _AccountMenuRow(icon: Icons.logout, label: LogoutStringsConstants.button.tr()),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    if (_navItems.length < 2) return const SizedBox.shrink();

    final safeIndex = _currentIndex.clamp(0, _navItems.length - 1);

    return NavigationBar(
      selectedIndex: safeIndex,
      onDestinationSelected: (i) => setState(() => _currentIndex = i),
      destinations: _navItems
          .map((item) => NavigationDestination(
                icon: Icon(MenuItemModel.iconOutlinedFromString(item.icon)),
                selectedIcon: Icon(MenuItemModel.iconFromString(item.icon)),
                label: item.localizedName,
              ))
          .toList(),
    );
  }
}

enum _AccountMenuAction { language, logout }

class _AccountMenuRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AccountMenuRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.whiteSubtle, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppColors.white, fontSize: 15)),
      ],
    );
  }
}
