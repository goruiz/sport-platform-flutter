import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/strings_constants/home_strings_constants.dart';
import 'package:sport_platform/core/modules/module_urls.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/utils/date_formatters.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/home/data/datasource/home_dashboard_service.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/home/presentation/enums/menu_style.dart';
import 'package:sport_platform/modules/home/presentation/widgets/drawer_hint_card.dart';
import 'package:sport_platform/modules/home/presentation/widgets/greeting_banner.dart';
import 'package:sport_platform/modules/home/presentation/widgets/quick_actions_carousel.dart';
import 'package:sport_platform/modules/home/presentation/widgets/section_header.dart';
import 'package:sport_platform/modules/home/presentation/widgets/empty_card.dart';

class HomeTab extends StatefulWidget {
  final HomeMenuStyle menuStyle;
  final List<MenuItemModel> menuItems;
  final bool isLoadingMenu;
  final bool menuError;
  final VoidCallback onRetryMenu;
  final ValueChanged<String>? onNavigate;

  const HomeTab({
    super.key,
    required this.menuStyle,
    required this.menuItems,
    required this.isLoadingMenu,
    required this.menuError,
    required this.onRetryMenu,
    this.onNavigate,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _dashboardService = HomeDashboardService();
  late Future<HomeDashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _dashboardService.load();
  }

  Future<void> _refreshDashboard() async {
    setState(() => _dashboardFuture = _dashboardService.load());
    await _dashboardFuture;
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      color: AppColors.primaryLight,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 20, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: GreetingBanner(),
            ),
            const SizedBox(height: 24),
            _section(
              title: HomeStringsConstants.sectionQuickActions.tr(),
              child: widget.menuStyle == HomeMenuStyle.carousel
                  ? QuickActionsCarousel(
                      items: widget.menuItems,
                      isLoading: widget.isLoadingMenu,
                      hasError: widget.menuError,
                      onRetry: widget.onRetryMenu,
                    )
                  : Builder(
                      builder: (ctx) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: DrawerHintCard(
                          onTap: () => Scaffold.of(ctx).openDrawer(),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            _section(
              title: HomeStringsConstants.sectionInvitations.tr(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: EmptyCard(
                  icon: Icons.mark_email_unread_outlined,
                  message: 'mobile.home.invitations_note'.tr(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FutureBuilder<HomeDashboardData>(
              future: _dashboardFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryLight),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: EmptyCard(
                      icon: Icons.cloud_off_outlined,
                      message: 'mobile.home.load_error'.tr(),
                      subtitle: 'mobile.home.retry_hint'.tr(),
                    ),
                  );
                }
                final data = snapshot.data!;
                return Column(
                  children: [
                    _section(
                      title: HomeStringsConstants.sectionNextEvent.tr(),
                      child: _eventPreview(data.nextEvent),
                    ),
                    const SizedBox(height: 24),
                    _section(
                      title: 'mobile.home.next_match'.tr(),
                      child: _matchPreview(
                        data.nextMatch,
                        data.teamName,
                        data.eventName,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _section(
                      title: HomeStringsConstants.sectionActiveTeams.tr(),
                      child: _teamPreview(data),
                    ),
                    const SizedBox(height: 24),
                    _section(
                      title: HomeStringsConstants.sectionRecentActivity.tr(),
                      child: _activityPreview(
                        data.latestResult,
                        data.teamName,
                        data.eventName,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({required String title, required Widget child}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SectionHeader(title: title),
          ),
          const SizedBox(height: 12),
          child,
        ],
      );

  Widget _eventPreview(EventModel? event) {
    if (event == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: EmptyCard(
          icon: Icons.event_outlined,
          message: HomeStringsConstants.noNextEvent.tr(),
          subtitle: HomeStringsConstants.noNextEventSubtitle.tr(),
        ),
      );
    }
    return _SummaryCard(
      icon: Icons.emoji_events_outlined,
      title: event.name,
      subtitle:
          '${DateFormatters.date(event.startDate)} – ${DateFormatters.date(event.endDate)}',
      onTap: () => widget.onNavigate?.call(ModuleUrls.events),
    );
  }

  Widget _matchPreview(
    MatchModel? match,
    String Function(String) teamName,
    String Function(String) eventName,
  ) {
    if (match == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: EmptyCard(
          icon: Icons.sports_soccer_outlined,
          message: 'mobile.home.no_next_match'.tr(),
        ),
      );
    }
    final event = eventName(match.eventId);
    return _SummaryCard(
      icon: Icons.sports_soccer_outlined,
      title: '${teamName(match.homeTeamId)}  vs  ${teamName(match.awayTeamId)}',
      subtitle: [
        DateFormatters.dateTime(match.matchDate),
        if (event.isNotEmpty) event,
      ].join(' · '),
      onTap: () => widget.onNavigate?.call(ModuleUrls.matches),
    );
  }

  Widget _teamPreview(HomeDashboardData data) {
    final team = data.currentTeam;
    if (team == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: EmptyCard(
          icon: Icons.groups_outlined,
          message: HomeStringsConstants.noTeamsTitle.tr(),
          subtitle: 'mobile.teams.no_membership'.tr(),
        ),
      );
    }
    return _SummaryCard(
      icon: Icons.shield_outlined,
      title: team.name,
      subtitle: 'mobile.teams.your_team'.tr(),
      onTap: () => widget.onNavigate?.call(ModuleUrls.teams),
    );
  }

  Widget _activityPreview(
    MatchModel? match,
    String Function(String) teamName,
    String Function(String) eventName,
  ) {
    if (match == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: EmptyCard(
          icon: Icons.timeline,
          message: HomeStringsConstants.noActivityTitle.tr(),
          subtitle: HomeStringsConstants.noActivitySubtitle.tr(),
        ),
      );
    }
    final event = eventName(match.eventId);
    return _SummaryCard(
      icon: Icons.sports_score_outlined,
      title:
          '${teamName(match.homeTeamId)} ${match.homeScore} – ${match.awayScore} ${teamName(match.awayTeamId)}',
      subtitle: [
        DateFormatters.date(match.matchDate),
        if (event.isNotEmpty) event,
      ].join(' · '),
      onTap: () => widget.onNavigate?.call(ModuleUrls.matches),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primaryLight, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.whiteSubtle,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(Icons.chevron_right,
                      color: AppColors.whiteSubtle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
