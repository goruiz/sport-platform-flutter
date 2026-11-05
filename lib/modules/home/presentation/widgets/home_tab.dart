import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/strings_constants/home_strings_constants.dart';
import 'package:sport_platform/core/modules/module_urls.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/core/utils/date_formatters.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/home/data/datasource/home_dashboard_service.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/home/presentation/enums/menu_style.dart';
import 'package:sport_platform/modules/home/presentation/widgets/drawer_hint_card.dart';
import 'package:sport_platform/modules/home/presentation/widgets/email_verification_banner.dart';
import 'package:sport_platform/modules/home/presentation/widgets/greeting_banner.dart';
import 'package:sport_platform/modules/home/presentation/widgets/invitations_card.dart';
import 'package:sport_platform/modules/home/presentation/widgets/join_team_card.dart';
import 'package:sport_platform/modules/home/presentation/widgets/next_match_card.dart';
import 'package:sport_platform/modules/home/presentation/widgets/quick_actions_grid.dart';
import 'package:sport_platform/modules/home/presentation/widgets/section_header.dart';
import 'package:sport_platform/modules/home/presentation/widgets/summary_tile.dart';
import 'package:sport_platform/modules/matches/presentation/pages/match_detail_page.dart';
import 'package:sport_platform/modules/matches/presentation/widgets/match_summary_card.dart';
import 'package:sport_platform/modules/players/presentation/pages/join_team_page.dart';
import 'package:sport_platform/shared/widgets/app_card.dart';
import 'package:sport_platform/shared/widgets/skeleton_box.dart';
import 'package:sport_platform/shared/widgets/initials_avatar.dart';

/// La pantalla de inicio: lo que le toca al jugador ahora mismo (su próximo partido, o cómo unirse a un equipo),
/// los accesos a todo lo demás y un resumen de su equipo, su último resultado y el próximo evento.
class HomeTab extends StatefulWidget {
  final HomeMenuStyle menuStyle;
  final List<MenuItemModel> menuItems;
  final bool isLoadingMenu;
  final bool menuError;
  final VoidCallback onRetryMenu;
  final VoidCallback onToggleMenuStyle;
  final ValueChanged<String>? onNavigate;

  const HomeTab({
    super.key,
    required this.menuStyle,
    required this.menuItems,
    required this.isLoadingMenu,
    required this.menuError,
    required this.onRetryMenu,
    required this.onToggleMenuStyle,
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

  Future<void> _joinWithCode() async {
    final joined = await JoinTeamPage.open(context);
    if (joined && mounted) await _refreshDashboard();
  }

  Future<void> _refreshDashboard() async {
    setState(() => _dashboardFuture = _dashboardService.load());
    await _dashboardFuture;
  }

  void _openMatch(MatchModel match, HomeDashboardData data) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MatchDetailPage(
          match: match,
          homeName: data.teamName(match.homeTeamId),
          awayName: data.teamName(match.awayTeamId),
          eventName: data.eventName(match.eventId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      color: AppColors.primaryLight,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.lg,
          AppSpacing.page,
          AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GreetingBanner(),
            const SizedBox(height: AppSpacing.xl),
            // Solo se dibujan cuando hay algo que atender: el correo sin confirmar y las invitaciones pendientes.
            const EmailVerificationBanner(),
            const InvitationsCard(),
            FutureBuilder<HomeDashboardData>(
              future: _dashboardFuture,
              builder: (context, snapshot) => _buildHeroSection(snapshot),
            ),
            const SizedBox(height: AppSpacing.section),
            _buildQuickActionsSection(),
            FutureBuilder<HomeDashboardData>(
              future: _dashboardFuture,
              builder: (context, snapshot) => _buildSummarySections(snapshot),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- partido destacado

  /// Lo primero de la pantalla: el próximo partido y, si el jugador no tiene equipo, cómo unirse a uno.
  Widget _buildHeroSection(AsyncSnapshot<HomeDashboardData> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _section(
        title: 'mobile.home.next_match'.tr(),
        child: const SkeletonBox(height: 190),
      );
    }
    if (snapshot.hasError) return _buildLoadError();

    final data = snapshot.data!;
    if (data.currentTeam == null) return JoinTeamCard(onJoin: _joinWithCode);

    final match = data.nextMatch();
    return _section(
      title: 'mobile.home.next_match'.tr(),
      child: match == null
          ? _buildNoNextMatch()
          : NextMatchCard(
              match: match,
              homeName: data.teamName(match.homeTeamId),
              awayName: data.teamName(match.awayTeamId),
              eventName: data.eventName(match.eventId),
              onTap: () => _openMatch(match, data),
            ),
    );
  }

  Widget _buildNoNextMatch() {
    return SummaryTile(
      leading: SummaryTile.iconBadge(Icons.sports_soccer_outlined),
      title: 'mobile.home.no_next_match'.tr(),
      subtitle: 'mobile.matches.empty_mine_subtitle'.tr(),
      onTap: () => widget.onNavigate?.call(ModuleUrls.matches),
    );
  }

  Widget _buildLoadError() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_off_outlined, color: AppColors.whiteSubtle, size: 26),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text('mobile.home.load_error'.tr(), style: AppTextStyles.cardTitle),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: _refreshDashboard,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text('common.retry'.tr()),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- accesos

  Widget _buildQuickActionsSection() {
    final isGrid = widget.menuStyle == HomeMenuStyle.grid;
    return _section(
      title: HomeStringsConstants.sectionQuickActions.tr(),
      action: IconButton(
        icon: Icon(
          isGrid ? Icons.view_sidebar_outlined : Icons.grid_view_outlined,
          color: AppColors.whiteSubtle,
          size: 22,
        ),
        tooltip: isGrid
            ? HomeStringsConstants.switchToDrawer.tr()
            : HomeStringsConstants.switchToGrid.tr(),
        onPressed: widget.onToggleMenuStyle,
      ),
      child: isGrid
          ? QuickActionsGrid(
              items: widget.menuItems,
              isLoading: widget.isLoadingMenu,
              hasError: widget.menuError,
              onRetry: widget.onRetryMenu,
            )
          : Builder(
              builder: (ctx) => DrawerHintCard(
                onTap: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
    );
  }

  // ---------------------------------------------------------------- resúmenes

  /// Tu equipo, tu último resultado y el próximo evento. Cada bloque solo aparece si tiene algo que contar,
  /// salvo el evento, que siempre invita a explorar.
  Widget _buildSummarySections(AsyncSnapshot<HomeDashboardData> snapshot) {
    final data = snapshot.data;
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Padding(
        padding: EdgeInsets.only(top: AppSpacing.section),
        child: SkeletonBox(height: 72),
      );
    }
    if (data == null) return const SizedBox.shrink();

    final team = data.currentTeam;
    final latestResult = data.latestResult();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (team != null) ...[
          const SizedBox(height: AppSpacing.section),
          _section(
            title: 'mobile.teams.your_team'.tr(),
            child: SummaryTile(
              leading: InitialsAvatar(name: team.name, logoUrl: team.logoUrl),
              title: team.name,
              subtitle: 'home.view_team'.tr(),
              onTap: () => widget.onNavigate?.call(ModuleUrls.teams),
            ),
          ),
        ],
        if (latestResult != null) ...[
          const SizedBox(height: AppSpacing.section),
          _section(
            title: HomeStringsConstants.sectionLatestResult.tr(),
            child: MatchSummaryCard(
              match: latestResult,
              homeName: data.teamName(latestResult.homeTeamId),
              awayName: data.teamName(latestResult.awayTeamId),
              eventName: data.eventName(latestResult.eventId),
              onTap: () => _openMatch(latestResult, data),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.section),
        _section(
          title: HomeStringsConstants.sectionNextEvent.tr(),
          child: _buildEventTile(data.nextEvent()),
        ),
      ],
    );
  }

  Widget _buildEventTile(EventModel? event) {
    if (event == null) {
      return SummaryTile(
        leading: SummaryTile.iconBadge(Icons.event_outlined),
        title: HomeStringsConstants.noNextEvent.tr(),
        subtitle: HomeStringsConstants.noNextEventSubtitle.tr(),
        onTap: () => widget.onNavigate?.call(ModuleUrls.events),
      );
    }
    return SummaryTile(
      leading: SummaryTile.iconBadge(Icons.emoji_events_outlined),
      title: event.name,
      subtitle: DateFormatters.shortRange(
        event.startDate,
        event.endDate,
        context.locale.languageCode,
      ),
      onTap: () => widget.onNavigate?.call(ModuleUrls.events),
    );
  }

  // ---------------------------------------------------------------- común

  Widget _section({required String title, required Widget child, Widget? action}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title, action: action),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      );
}
