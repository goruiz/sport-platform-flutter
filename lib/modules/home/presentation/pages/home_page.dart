import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/strings_constants/app_strings_constants.dart';
import 'package:sport_platform/core/constants/strings_constants/home_strings_constants.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/home/data/services/menu_service.dart';
import 'package:sport_platform/shared/widgets/language_selector.dart';
import 'package:sport_platform/shared/widgets/logout_button.dart';

enum _MenuStyle { carousel, drawer }

const List<Color> _kMenuColors = [
  Color(0xFF2E7D32),
  Color(0xFFE65100),
  Color(0xFF1565C0),
  Color(0xFFF57F17),
  Color(0xFF00695C),
  Color(0xFF6A1B9A),
  Color(0xFFAD1457),
  Color(0xFF37474F),
];

// ─────────────────────── Home Page ───────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  _MenuStyle _menuStyle = _MenuStyle.carousel;

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
      drawer: _menuStyle == _MenuStyle.drawer
          ? _QuickActionsDrawer(
              items: _menuItems,
              isLoading: _isLoadingMenu,
              hasError: _menuError,
              onRetry: _loadMenu,
            )
          : null,
      body: _currentIndex == 0
          ? _HomeTab(
              menuStyle: _menuStyle,
              menuItems: _menuItems,
              isLoadingMenu: _isLoadingMenu,
              menuError: _menuError,
              onRetryMenu: _loadMenu,
            )
          : _PlaceholderTab(index: _currentIndex),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryDark,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: _menuStyle == _MenuStyle.drawer
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
            _menuStyle == _MenuStyle.carousel
                ? Icons.view_sidebar_outlined
                : Icons.view_carousel_outlined,
            color: AppColors.white,
          ),
          tooltip: _menuStyle == _MenuStyle.carousel
              ? HomeStringsConstants.switchToDrawer.tr()
              : HomeStringsConstants.switchToCarousel.tr(),
          onPressed: () => setState(() {
            _menuStyle = _menuStyle == _MenuStyle.carousel
                ? _MenuStyle.drawer
                : _MenuStyle.carousel;
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
      selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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

// ─────────────────────── Home Tab ───────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final _MenuStyle menuStyle;
  final List<MenuItemModel> menuItems;
  final bool isLoadingMenu;
  final bool menuError;
  final VoidCallback onRetryMenu;

  const _HomeTab({
    required this.menuStyle,
    required this.menuItems,
    required this.isLoadingMenu,
    required this.menuError,
    required this.onRetryMenu,
  });

  @override
  Widget build(BuildContext context) {
    context.locale;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 20, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: _GreetingBanner(),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _SectionHeader(title: HomeStringsConstants.sectionQuickActions.tr()),
          ),
          const SizedBox(height: 12),
          if (menuStyle == _MenuStyle.carousel)
            _QuickActionsCarousel(
              items: menuItems,
              isLoading: isLoadingMenu,
              hasError: menuError,
              onRetry: onRetryMenu,
            )
          else
            Builder(
              builder: (ctx) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _DrawerHintCard(
                  onTap: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
            ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _SectionHeader(title: HomeStringsConstants.sectionInvitations.tr()),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: _InvitationsCard(),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _SectionHeader(title: HomeStringsConstants.sectionNextEvent.tr()),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: _NextEventCard(),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _SectionHeader(
              title: HomeStringsConstants.sectionActiveTeams.tr(),
              trailing: HomeStringsConstants.viewAll.tr(),
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: _TeamsCard(),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _SectionHeader(title: HomeStringsConstants.sectionRecentActivity.tr()),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: _ActivityCard(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── Greeting Banner ────────────────────────────────────

class _GreetingBanner extends StatelessWidget {
  const _GreetingBanner();

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return HomeStringsConstants.greetingMorning.tr();
    if (h < 18) return HomeStringsConstants.greetingAfternoon.tr();
    return HomeStringsConstants.greetingEvening.tr();
  }

  @override
  Widget build(BuildContext context) {
    final name = HomeStringsConstants.guestName.tr();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.primaryLight,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────── Section Header ─────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (trailing != null)
          GestureDetector(
            onTap: () {},
            child: Text(
              trailing!,
              style: const TextStyle(
                color: AppColors.primaryLight,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────── Quick Actions Carousel ──────────────────────────────

class _QuickActionsCarousel extends StatefulWidget {
  final List<MenuItemModel> items;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onRetry;

  const _QuickActionsCarousel({
    required this.items,
    required this.isLoading,
    required this.hasError,
    required this.onRetry,
  });

  @override
  State<_QuickActionsCarousel> createState() => _QuickActionsCarouselState();
}

class _QuickActionsCarouselState extends State<_QuickActionsCarousel> {
  late final PageController _controller;
  int _currentPage = 0;

  static const int _itemsPerPage = 3;

  int get _pageCount => (widget.items.length / _itemsPerPage).ceil().clamp(1, 999);

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) return _buildLoading();
    if (widget.hasError) return _buildError();
    if (widget.items.isEmpty) return _buildEmpty();

    return Column(
      children: [
        SizedBox(
          height: 110,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
              },
            ),
            child: PageView.builder(
              controller: _controller,
              itemCount: _pageCount,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (_, pageIndex) {
                final start = pageIndex * _itemsPerPage;
                final end = (start + _itemsPerPage).clamp(0, widget.items.length);
                final pageItems = widget.items.sublist(start, end);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      for (int i = 0; i < pageItems.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(
                          child: _QuickActionCard(
                            item: pageItems[i],
                            color: _kMenuColors[(start + i) % _kMenuColors.length],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _pageCount,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == _currentPage ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == _currentPage
                    ? AppColors.primary
                    : AppColors.whiteSubtle.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return SizedBox(
      height: 110,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: List.generate(3, (i) => [
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.primaryLight,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
            ),
          ]).expand((e) => e).toList(),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: widget.onRetry,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.refresh, color: AppColors.primaryLight, size: 20),
              SizedBox(width: 8),
              Text(
                'Error al cargar el menú. Toca para reintentar.',
                style: TextStyle(color: AppColors.whiteSubtle, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: const Center(
          child: Text(
            'Sin acciones disponibles',
            style: TextStyle(color: AppColors.whiteSubtle, fontSize: 13),
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final MenuItemModel item;
  final Color color;

  const _QuickActionCard({required this.item, required this.color});

  void _onTap(BuildContext context) {
    if (!item.hasChildren) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primaryDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ChildrenSheet(parent: item, parentColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final icon = MenuItemModel.iconFromString(item.icon);
    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                if (item.hasChildren)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.expand_more, color: Colors.white, size: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                item.name,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────── Children Bottom Sheet ───────────────────────────────

class _ChildrenSheet extends StatelessWidget {
  final MenuItemModel parent;
  final Color parentColor;

  const _ChildrenSheet({required this.parent, required this.parentColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.whiteSubtle.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: parentColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    MenuItemModel.iconFromString(parent.icon),
                    color: parentColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  parent.name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Divider(color: AppColors.inputBorder, height: 24),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: parent.children.length,
            itemBuilder: (_, i) {
              final child = parent.children[i];
              final color = _kMenuColors[i % _kMenuColors.length];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(MenuItemModel.iconFromString(child.icon), color: color, size: 18),
                ),
                title: Text(
                  child.name,
                  style: const TextStyle(color: AppColors.white, fontSize: 14),
                ),
                subtitle: child.description != null && child.description!.isNotEmpty
                    ? Text(
                        child.description!,
                        style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 12),
                      )
                    : null,
                onTap: () => Navigator.pop(context),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── Quick Actions Drawer ────────────────────────────────

class _QuickActionsDrawer extends StatelessWidget {
  final List<MenuItemModel> items;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onRetry;

  const _QuickActionsDrawer({
    required this.items,
    required this.isLoading,
    required this.hasError,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Drawer(
      backgroundColor: AppColors.primaryDark,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primaryDark,
              border: Border(
                bottom: BorderSide(color: AppColors.inputBorder),
              ),
            ),
            margin: EdgeInsets.zero,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                HomeStringsConstants.sectionQuickActions.tr(),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryLight),
      );
    }
    if (hasError) {
      return Center(
        child: GestureDetector(
          onTap: onRetry,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh, color: AppColors.primaryLight, size: 32),
              SizedBox(height: 8),
              Text(
                'Error al cargar. Toca para reintentar.',
                style: TextStyle(color: AppColors.whiteSubtle, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Sin acciones disponibles',
          style: TextStyle(color: AppColors.whiteSubtle, fontSize: 13),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final color = _kMenuColors[i % _kMenuColors.length];
        final leadingWidget = Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(MenuItemModel.iconFromString(item.icon), color: color, size: 22),
        );

        if (item.hasChildren) {
          return Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              splashColor: color.withValues(alpha: 0.1),
            ),
            child: ExpansionTile(
              leading: leadingWidget,
              title: Text(
                item.name,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: item.description != null && item.description!.isNotEmpty
                  ? Text(
                      item.description!,
                      style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 12),
                    )
                  : null,
              iconColor: color,
              collapsedIconColor: AppColors.whiteSubtle,
              tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              childrenPadding: EdgeInsets.zero,
              children: item.children.asMap().entries.map((entry) {
                final childIndex = entry.key;
                final child = entry.value;
                final childColor = _kMenuColors[childIndex % _kMenuColors.length];
                return ListTile(
                  contentPadding: const EdgeInsets.only(left: 80, right: 20, top: 2, bottom: 2),
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: childColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(MenuItemModel.iconFromString(child.icon), color: childColor, size: 16),
                  ),
                  title: Text(
                    child.name,
                    style: const TextStyle(color: AppColors.white, fontSize: 13),
                  ),
                  subtitle: child.description != null && child.description!.isNotEmpty
                      ? Text(
                          child.description!,
                          style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 11),
                        )
                      : null,
                  onTap: () => Navigator.pop(context),
                );
              }).toList(),
            ),
          );
        }

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: leadingWidget,
          title: Text(
            item.name,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: item.description != null && item.description!.isNotEmpty
              ? Text(
                  item.description!,
                  style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 12),
                )
              : null,
          onTap: () => Navigator.pop(context),
        );
      },
    );
  }
}

// ─────────────────────── Drawer Hint Card ────────────────────────────────────

class _DrawerHintCard extends StatelessWidget {
  final VoidCallback onTap;

  const _DrawerHintCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.menu, color: AppColors.primaryLight, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                HomeStringsConstants.openSideMenu.tr(),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.whiteSubtle, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────── Invitations ────────────────────────────────────────

class _InvitationsCard extends StatelessWidget {
  const _InvitationsCard();

  @override
  Widget build(BuildContext context) {
    return _EmptyCard(
      icon: Icons.check_circle_outline,
      message: HomeStringsConstants.noInvitations.tr(),
    );
  }
}

// ─────────────────────── Next Event ─────────────────────────────────────────

class _NextEventCard extends StatelessWidget {
  const _NextEventCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_outlined, color: AppColors.whiteSubtle, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  HomeStringsConstants.noNextEvent.tr(),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  HomeStringsConstants.noNextEventSubtitle.tr(),
                  style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: Text(
                HomeStringsConstants.exploreEvents.tr(),
                style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── Teams Card ─────────────────────────────────────────

class _TeamsCard extends StatelessWidget {
  const _TeamsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: const Icon(Icons.add, color: AppColors.primaryLight, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  HomeStringsConstants.noTeamsTitle.tr(),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  HomeStringsConstants.noTeamsSubtitle.tr(),
                  style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── Activity Card ──────────────────────────────────────

class _ActivityCard extends StatelessWidget {
  const _ActivityCard();

  @override
  Widget build(BuildContext context) {
    return _EmptyCard(
      icon: Icons.timeline,
      message: HomeStringsConstants.noActivityTitle.tr(),
      subtitle: HomeStringsConstants.noActivitySubtitle.tr(),
    );
  }
}

// ─────────────────────── Shared: Empty Card ─────────────────────────────────

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;

  const _EmptyCard({required this.icon, required this.message, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.whiteSubtle, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 13),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── Placeholder Tab ────────────────────────────────────

class _PlaceholderTab extends StatelessWidget {
  final int index;

  const _PlaceholderTab({required this.index});

  static const _icons = [
    Icons.home,
    Icons.group,
    Icons.event,
    Icons.leaderboard,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        _icons[index],
        color: AppColors.whiteSubtle,
        size: 48,
      ),
    );
  }
}
