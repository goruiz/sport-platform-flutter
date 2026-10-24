import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/network/response_parser.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/utils/date_formatters.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/courts_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/teams_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/court_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/team_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/enums/match_status.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/shared/widgets/empty_state.dart';
import 'package:sport_platform/shared/widgets/error_retry.dart';

class MatchesPage extends StatefulWidget {
  final MenuItemModel item;

  const MatchesPage({super.key, required this.item});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage>
    with SingleTickerProviderStateMixin {
  final _client = DioClient();
  late final TabController _tabController;
  late Future<_MatchesData> _matchesFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _matchesFuture = _loadMatches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<_MatchesData> _loadMatches() async {
    final responses = await Future.wait<dynamic>([
      _client.get(ApiEndpoints.matches),
      _client.get(ApiEndpoints.events),
      getIt<TeamsService>().getAll(),
      getIt<CourtsService>().getAll(),
    ]);
    return _MatchesData(
      matches: ResponseParser.toList(responses[0].data)
          .map((item) => MatchModel.fromJson(item as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.matchDate.compareTo(b.matchDate)),
      events: ResponseParser.toList(responses[1].data)
          .map((item) => EventModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      teams: responses[2] as List<TeamModel>,
      courts: responses[3] as List<CourtModel>,
    );
  }

  Future<void> _reload() async {
    setState(() => _matchesFuture = _loadMatches());
    await _matchesFuture;
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Scaffold(
      backgroundColor: AppColors.backgroundEnd,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: Text(widget.item.displayName.tr(),
            style: const TextStyle(color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
        actions: [
          IconButton(
            onPressed: _reload,
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
      body: FutureBuilder<_MatchesData>(
        future: _matchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryLight),
            );
          }
          if (snapshot.hasError) {
            return ErrorRetry(
              message: 'mobile.matches.load_error'.tr(),
              onRetry: _reload,
            );
          }
          final data = snapshot.data!;
          return TabBarView(
            controller: _tabController,
            children: [
              _buildMatchList(data, _upcomingMatches(data.matches)),
              _buildMatchList(data, _completedMatches(data.matches)),
              _buildMatchList(data, data.matches),
            ],
          );
        },
      ),
    );
  }

  List<MatchModel> _upcomingMatches(List<MatchModel> matches) {
    final now = DateTime.now();
    return matches
        .where((match) =>
            match.matchDate.isAfter(now) &&
            match.status != MatchStatus.cancelled)
        .toList();
  }

  List<MatchModel> _completedMatches(List<MatchModel> matches) => matches
      .where((match) => match.homeScore != null && match.awayScore != null)
      .toList()
    ..sort((a, b) => b.matchDate.compareTo(a.matchDate));

  Widget _buildMatchList(_MatchesData data, List<MatchModel> matches) {
    if (matches.isEmpty) {
      return RefreshIndicator(
        onRefresh: _reload,
        color: AppColors.primaryLight,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.65,
              child: EmptyState(
                icon: Icons.sports_soccer_outlined,
                title: 'mobile.matches.empty_title'.tr(),
                subtitle: 'mobile.matches.empty_subtitle'.tr(),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _reload,
      color: AppColors.primaryLight,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        itemCount: matches.length,
        itemBuilder: (context, index) => _MatchCard(
          match: matches[index],
          homeName: data.teamName(matches[index].homeTeamId),
          awayName: data.teamName(matches[index].awayTeamId),
          eventName: data.eventName(matches[index].eventId),
          courtName: data.courtName(matches[index].courtId),
        ),
      ),
    );
  }
}

class _MatchesData {
  final List<MatchModel> matches;
  final List<EventModel> events;
  final List<TeamModel> teams;
  final List<CourtModel> courts;

  const _MatchesData({
    required this.matches,
    required this.events,
    required this.teams,
    required this.courts,
  });

  String teamName(String id) {
    for (final team in teams) {
      if (team.id == id) return team.name;
    }
    return '—';
  }

  String eventName(String id) {
    for (final event in events) {
      if (event.id == id) return event.name;
    }
    return '';
  }

  String? courtName(String? id) {
    if (id == null) return null;
    for (final court in courts) {
      if (court.id == id) return court.displayName;
    }
    return null;
  }
}

class _MatchCard extends StatelessWidget {
  final MatchModel match;
  final String homeName;
  final String awayName;
  final String eventName;
  final String? courtName;

  const _MatchCard({
    required this.match,
    required this.homeName,
    required this.awayName,
    required this.eventName,
    required this.courtName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormatters.dateTime(match.matchDate),
                  style: const TextStyle(
                    color: AppColors.whiteSubtle,
                    fontSize: 12,
                  ),
                ),
              ),
              _StatusBadge(status: match.status),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  homeName,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  match.homeScore != null && match.awayScore != null
                      ? '${match.homeScore} - ${match.awayScore}'
                      : 'VS',
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  awayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (eventName.isNotEmpty || courtName != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                if (eventName.isNotEmpty)
                  _MatchMetadata(
                    icon: Icons.emoji_events_outlined,
                    text: eventName,
                  ),
                if (courtName != null)
                  _MatchMetadata(
                    icon: Icons.location_on_outlined,
                    text: courtName!,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final MatchStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: status.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status.label.tr(),
          style: TextStyle(
            color: status.color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

class _MatchMetadata extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MatchMetadata({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.whiteSubtle),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.whiteSubtle, fontSize: 12),
            ),
          ),
        ],
      );
}
