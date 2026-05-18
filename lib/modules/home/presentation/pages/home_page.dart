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

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Scaffold(
      backgroundColor: AppColors.backgroundEnd,
      appBar: _buildAppBar(),
      body: _buildBody(),
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

  Widget _buildBody() {
    return _HomeContent();
  }

  Widget _buildBottomNav() {
    final navItems = [
      _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: HomeStringsConstants.navHome.tr()),
      _NavItem(icon: Icons.group_outlined, activeIcon: Icons.group, label: HomeStringsConstants.navTeams.tr()),
      _NavItem(icon: Icons.event_outlined, activeIcon: Icons.event, label: HomeStringsConstants.navEvents.tr()),
      _NavItem(icon: Icons.leaderboard_outlined, activeIcon: Icons.leaderboard, label: HomeStringsConstants.navRankings.tr()),
      _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: HomeStringsConstants.navProfile.tr()),
    ];

    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      backgroundColor: AppColors.primaryDark,
      selectedItemColor: AppColors.primaryLight,
      unselectedItemColor: AppColors.whiteSubtle,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      items: navItems
          .map(
            (item) => BottomNavigationBarItem(
              icon: Icon(item.icon),
              activeIcon: Icon(item.activeIcon),
              label: item.label,
            ),
          )
          .toList(),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    context.locale;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeBanner(),
          const SizedBox(height: 28),
          _buildSectionTitle(HomeStringsConstants.sectionUpcomingEvents.tr()),
          const SizedBox(height: 12),
          _buildPlaceholderCard(
            icon: Icons.event_outlined,
            title: HomeStringsConstants.noEventsTitle.tr(),
            subtitle: HomeStringsConstants.noEventsSubtitle.tr(),
          ),
          const SizedBox(height: 28),
          _buildSectionTitle(HomeStringsConstants.sectionMyTeams.tr()),
          const SizedBox(height: 12),
          _buildPlaceholderCard(
            icon: Icons.group_outlined,
            title: HomeStringsConstants.noTeamsTitle.tr(),
            subtitle: HomeStringsConstants.noTeamsSubtitle.tr(),
          ),
          const SizedBox(height: 28),
          _buildSectionTitle(HomeStringsConstants.sectionRankings.tr()),
          const SizedBox(height: 12),
          _buildPlaceholderCard(
            icon: Icons.leaderboard_outlined,
            title: HomeStringsConstants.noRankingsTitle.tr(),
            subtitle: HomeStringsConstants.noRankingsSubtitle.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.backgroundStart],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            HomeStringsConstants.welcomeLabel.tr(),
            style: const TextStyle(
              color: AppColors.whiteSubtle,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppStringsConstants.appName.tr(),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            HomeStringsConstants.welcomeSubtitle.tr(),
            style: const TextStyle(
              color: AppColors.whiteSubtle,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildPlaceholderCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.whiteSubtle, size: 36),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
