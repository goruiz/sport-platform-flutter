import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_input_decoration.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/standings_tab.dart';
import 'package:sport_platform/modules/events/shared/data/datasource/events_catalog_service.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/events/shared/presentation/widgets/championship_tab.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/rankings/data/datasource/player_stats_service.dart';
import 'package:sport_platform/modules/rankings/data/models/player_stats_model.dart';
import 'package:sport_platform/modules/rankings/domain/leaderboards.dart';
import 'package:sport_platform/modules/rankings/presentation/widgets/leaderboard_list.dart';
import 'package:sport_platform/shared/widgets/empty_state.dart';
import 'package:sport_platform/shared/widgets/error_retry.dart';

/// Las posiciones y los líderes (goles, asistencias, tarjetas) del evento que el usuario elija.
class RankingsPage extends StatefulWidget {
  final MenuItemModel item;

  const RankingsPage({super.key, required this.item});

  @override
  State<RankingsPage> createState() => _RankingsPageState();
}

class _RankingsPageState extends State<RankingsPage>
    with SingleTickerProviderStateMixin {
  // Posiciones y uno por cada listado de jugadores.
  static final _tabCount = 1 + LeaderboardKind.values.length;

  late final TabController _tabController;
  late Future<List<EventModel>> _eventsFuture;
  Future<List<PlayerStatsModel>>? _statsFuture;
  EventModel? _selectedEvent;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
    _eventsFuture = _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<EventModel>> _loadEvents() async {
    final events = await getIt<EventsCatalogService>().getAll();
    final defaultEvent = pickDefaultEvent(events);
    if (_selectedEvent == null && defaultEvent != null) _selectEvent(defaultEvent);
    return events;
  }

  void _selectEvent(EventModel event) {
    _selectedEvent = event;
    _statsFuture = getIt<PlayerStatsService>().getByEvent(event.id);
  }

  Future<void> _reloadStats() async {
    final event = _selectedEvent;
    if (event == null) return;
    setState(() => _selectEvent(event));
    await _statsFuture;
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
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.primaryLight,
          unselectedLabelColor: AppColors.whiteSubtle,
          indicatorColor: AppColors.primaryLight,
          tabs: [
            Tab(text: 'rankings.standings'.tr()),
            for (final kind in LeaderboardKind.values) Tab(text: kind.translationKey.tr()),
          ],
        ),
      ),
      body: FutureBuilder<List<EventModel>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryLight),
            );
          }
          if (snapshot.hasError) {
            return ErrorRetry(
              message: 'rankings.load_error'.tr(),
              onRetry: () => setState(() => _eventsFuture = _loadEvents()),
            );
          }
          final events = snapshot.data ?? const <EventModel>[];
          if (events.isEmpty || _selectedEvent == null) {
            return EmptyState(
              icon: Icons.emoji_events_outlined,
              title: 'rankings.no_events_title'.tr(),
              subtitle: 'rankings.no_events_subtitle'.tr(),
            );
          }
          return Column(
            children: [
              _buildEventSelector(events),
              Expanded(child: _buildTabs(_selectedEvent!)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventSelector(List<EventModel> events) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: DropdownButtonFormField<String>(
        // ignore: deprecated_member_use
        value: _selectedEvent!.id,
        isExpanded: true,
        items: events
            .map((event) => DropdownMenuItem(
                  value: event.id,
                  child: Text(event.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.white)),
                ))
            .toList(),
        onChanged: (eventId) {
          final event = events.firstWhere((candidate) => candidate.id == eventId);
          setState(() => _selectEvent(event));
        },
        dropdownColor: AppColors.sheetBackground,
        style: const TextStyle(color: AppColors.white),
        decoration: AppInputDecoration.standard('rankings.event'.tr()),
      ),
    );
  }

  Widget _buildTabs(EventModel event) {
    return TabBarView(
      controller: _tabController,
      children: [
        // La llave de la clave fuerza a releer las posiciones al cambiar de evento.
        event.hasChampionship
            ? ChampionshipTab(key: ValueKey(event.id), eventId: event.id, isOwner: false)
            : StandingsTab(key: ValueKey(event.id), eventId: event.id),
        ..._buildLeaderboardTabs(),
      ],
    );
  }

  List<Widget> _buildLeaderboardTabs() {
    return LeaderboardKind.values.map((kind) {
      return FutureBuilder<List<PlayerStatsModel>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryLight),
            );
          }
          if (snapshot.hasError) {
            return ErrorRetry(message: 'rankings.load_error'.tr(), onRetry: _reloadStats);
          }
          return LeaderboardList(
            stats: snapshot.data ?? const [],
            kind: kind,
            onRefresh: _reloadStats,
          );
        },
      );
    }).toList();
  }
}
