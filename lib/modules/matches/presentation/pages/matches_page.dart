import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/matches/domain/match_rules.dart';
import 'package:sport_platform/modules/matches/presentation/pages/match_detail_page.dart';
import 'package:sport_platform/modules/matches/presentation/providers/matches_notifier.dart';
import 'package:sport_platform/modules/matches/presentation/widgets/match_summary_card.dart';
import 'package:sport_platform/shared/widgets/empty_state.dart';
import 'package:sport_platform/shared/widgets/error_retry.dart';

/// Los partidos del equipo del usuario (por defecto) o de toda la plataforma, en tres vistas:
/// próximos, resultados y todos. Un partido se abre para ver su cronología.
class MatchesPage extends StatefulWidget {
  final MenuItemModel item;

  const MatchesPage({super.key, required this.item});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final MatchesNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _notifier = MatchesNotifier(
      matchesService: getIt(),
      eventsService: getIt(),
      teamsService: getIt(),
      courtsService: getIt(),
    )..load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notifier.dispose();
    super.dispose();
  }

  void _openMatch(MatchModel match) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MatchDetailPage(
          match: match,
          homeName: _notifier.teamName(match.homeTeamId),
          awayName: _notifier.teamName(match.awayTeamId),
          eventName: _notifier.eventName(match.eventId),
          courtName: _notifier.courtName(match.courtId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Scaffold(
      backgroundColor: AppColors.backgroundEnd,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: Text(widget.item.localizedName,
            style: const TextStyle(color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
        actions: [
          IconButton(
            onPressed: _notifier.load,
            tooltip: 'common.retry'.tr(),
            icon: const Icon(Icons.refresh, color: AppColors.white),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryLight,
          unselectedLabelColor: AppColors.whiteSubtle,
          indicatorColor: AppColors.primaryLight,
          tabs: [
            Tab(text: 'mobile.matches.upcoming'.tr()),
            Tab(text: 'mobile.matches.results'.tr()),
            Tab(text: 'mobile.matches.all'.tr()),
          ],
        ),
      ),
      body: ListenableBuilder(listenable: _notifier, builder: (_, _) => _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_notifier.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryLight),
      );
    }
    final error = _notifier.error;
    if (error != null && _notifier.visibleMatches.isEmpty) {
      return ErrorRetry(message: error.tr(), onRetry: _notifier.load);
    }
    return Column(
      children: [
        _buildScopeSelector(),
        Expanded(
          child: _notifier.loadingAll
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryLight),
                )
              : _buildTabs(),
        ),
      ],
    );
  }

  Widget _buildScopeSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SegmentedButton<MatchesScope>(
        segments: [
          ButtonSegment(
            value: MatchesScope.mine,
            icon: const Icon(Icons.shield_outlined),
            label: Text('mobile.matches.scope_mine'.tr()),
          ),
          ButtonSegment(
            value: MatchesScope.all,
            icon: const Icon(Icons.public),
            label: Text('mobile.matches.scope_all'.tr()),
          ),
        ],
        selected: {_notifier.scope},
        onSelectionChanged: (selection) => _notifier.selectScope(selection.first),
        showSelectedIcon: false,
      ),
    );
  }

  Widget _buildTabs() {
    final matches = _notifier.visibleMatches;
    final now = DateTime.now();
    return TabBarView(
      controller: _tabController,
      children: [
        _buildMatchList(upcomingMatches(matches, now)),
        _buildMatchList(playedMatches(matches)),
        _buildMatchList(matches),
      ],
    );
  }

  Widget _buildMatchList(List<MatchModel> matches) {
    if (matches.isEmpty) {
      return RefreshIndicator(
        onRefresh: _notifier.load,
        color: AppColors.primaryLight,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.55,
              child: EmptyState(
                icon: Icons.sports_soccer_outlined,
                title: 'mobile.matches.empty_title'.tr(),
                subtitle: _notifier.scope == MatchesScope.mine
                    ? 'mobile.matches.empty_mine_subtitle'.tr()
                    : 'mobile.matches.empty_subtitle'.tr(),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _notifier.load,
      color: AppColors.primaryLight,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final match = matches[index];
          return MatchSummaryCard(
            match: match,
            homeName: _notifier.teamName(match.homeTeamId),
            awayName: _notifier.teamName(match.awayTeamId),
            eventName: _notifier.eventName(match.eventId),
            courtName: _notifier.courtName(match.courtId),
            onTap: () => _openMatch(match),
          );
        },
      ),
    );
  }
}
