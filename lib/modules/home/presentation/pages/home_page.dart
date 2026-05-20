import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/strings_constants/app_strings_constants.dart';
import 'package:sport_platform/core/constants/strings_constants/home_strings_constants.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/shared/widgets/language_selector.dart';
import 'package:sport_platform/shared/widgets/logout_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

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
  Widget build(BuildContext context) {
    context.locale;
    return Scaffold(
      backgroundColor: AppColors.backgroundEnd,
      appBar: _buildAppBar(),
      body: _currentIndex == 0 ? const _HomeTab() : _PlaceholderTab(index: _currentIndex),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryDark,
      elevation: 0,
      title: Text(
        AppStringsConstants.appName.tr(),
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: const [
        LanguageSelector(),
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: AppColors.white),
          onPressed: null,
        ),
        LogoutButton(),
        SizedBox(width: 4),
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
  const _HomeTab();

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
          const _QuickActionsCarousel(),
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

class _QuickActionItem {
  final IconData icon;
  final String labelKey;
  final Color color;

  const _QuickActionItem({
    required this.icon,
    required this.labelKey,
    required this.color,
  });
}

class _QuickActionsCarousel extends StatelessWidget {
  const _QuickActionsCarousel();

  static const List<_QuickActionItem> _items = [
    _QuickActionItem(
      icon: Icons.group_add,
      labelKey: HomeStringsConstants.actionCreateTeam,
      color: Color(0xFF2E7D32),
    ),
    _QuickActionItem(
      icon: Icons.emoji_events,
      labelKey: HomeStringsConstants.actionCreateTournament,
      color: Color(0xFFE65100),
    ),
    _QuickActionItem(
      icon: Icons.sports_soccer,
      labelKey: HomeStringsConstants.actionCreateLeague,
      color: Color(0xFF1565C0),
    ),
    _QuickActionItem(
      icon: Icons.workspace_premium,
      labelKey: HomeStringsConstants.actionBuyPlan,
      color: Color(0xFFF57F17),
    ),
    _QuickActionItem(
      icon: Icons.login,
      labelKey: HomeStringsConstants.actionJoinLeague,
      color: Color(0xFF00695C),
    ),
    _QuickActionItem(
      icon: Icons.sports,
      labelKey: HomeStringsConstants.actionMyMatches,
      color: Color(0xFF6A1B9A),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _QuickActionCard(item: _items[i]),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final _QuickActionItem item;

  const _QuickActionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 96,
        decoration: BoxDecoration(
          color: item.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: item.color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.color, size: 22),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                item.labelKey.tr(),
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
