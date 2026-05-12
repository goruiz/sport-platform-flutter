import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/strings_constants/app_strings_constants.dart';
import 'package:sport_platform/core/constants/strings_constants/home_strings_constants.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/shared/widgets/logout_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: HomeStringsConstants.navHome),
    _NavItem(icon: Icons.group_outlined, activeIcon: Icons.group, label: HomeStringsConstants.navTeams),
    _NavItem(icon: Icons.event_outlined, activeIcon: Icons.event, label: HomeStringsConstants.navEvents),
    _NavItem(icon: Icons.leaderboard_outlined, activeIcon: Icons.leaderboard, label: HomeStringsConstants.navRankings),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: HomeStringsConstants.navProfile),
  ];

  @override
  Widget build(BuildContext context) {
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
      title: const Text(
        AppStringsConstants.appName,
        style: TextStyle(
          color: AppColors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppColors.white),
          onPressed: () {},
        ),
        const LogoutButton(),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBody() {
    return const _HomeContent();
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      backgroundColor: AppColors.primaryDark,
      selectedItemColor: AppColors.primaryLight,
      unselectedItemColor: AppColors.whiteSubtle,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      items: _navItems
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeBanner(),
          const SizedBox(height: 28),
          _buildSectionTitle(HomeStringsConstants.sectionUpcomingEvents),
          const SizedBox(height: 12),
          _buildPlaceholderCard(
            icon: Icons.event_outlined,
            title: HomeStringsConstants.noEventsTitle,
            subtitle: HomeStringsConstants.noEventsSubtitle,
          ),
          const SizedBox(height: 28),
          _buildSectionTitle(HomeStringsConstants.sectionMyTeams),
          const SizedBox(height: 12),
          _buildPlaceholderCard(
            icon: Icons.group_outlined,
            title: HomeStringsConstants.noTeamsTitle,
            subtitle: HomeStringsConstants.noTeamsSubtitle,
          ),
          const SizedBox(height: 28),
          _buildSectionTitle(HomeStringsConstants.sectionRankings),
          const SizedBox(height: 12),
          _buildPlaceholderCard(
            icon: Icons.leaderboard_outlined,
            title: HomeStringsConstants.noRankingsTitle,
            subtitle: HomeStringsConstants.noRankingsSubtitle,
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            HomeStringsConstants.welcomeLabel,
            style: TextStyle(
              color: AppColors.whiteSubtle,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            AppStringsConstants.appName,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Text(
            HomeStringsConstants.welcomeSubtitle,
            style: TextStyle(
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
