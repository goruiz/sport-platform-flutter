import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/app_constants.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/pages/league_detail_page.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/events/shared/data/providers/events_explorer_notifier.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/event_status.dart';
import 'package:sport_platform/modules/events/shared/presentation/widgets/event_card.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/teams/presentation/widgets/active_team_pill.dart';
import 'package:sport_platform/shared/widgets/app_search_field.dart';
import 'package:sport_platform/shared/widgets/empty_state.dart';
import 'package:sport_platform/shared/widgets/error_retry.dart';

/// Explorar los eventos: por defecto los del equipo activo del jugador (el que eligió en «Equipo»; con varios equipos se
/// cambia desde aquí) o, a elección, todos los que ve (los de su organización y los públicos). Se busca por texto, se filtra
/// por estado y se descargan de a poco, porque la lista puede crecer con todos los eventos públicos de la plataforma.
class EventsPage extends StatefulWidget {
  final MenuItemModel item;

  const EventsPage({super.key, required this.item});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  /// Los estados que se ofrecen para filtrar; «cancelado» no sirve para explorar.
  static const _filterableStatuses = [EventStatus.active, EventStatus.upcoming, EventStatus.finished];

  /// A cuántos píxeles del final de la lista se pide la página que sigue.
  static const _loadMoreThreshold = 300.0;

  late final EventsExplorerNotifier _explorer;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _explorer = EventsExplorerNotifier(
      searchService: getIt(),
      teamEventsService: getIt(),
      playersService: getIt(),
      activeTeam: getIt(),
    );
    _scrollController.addListener(_loadMoreNearTheEnd);
    _explorer.load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _explorer.dispose();
    super.dispose();
  }

  void _loadMoreNearTheEnd() {
    final position = _scrollController.position;
    if (position.extentAfter < _loadMoreThreshold) _explorer.loadMore();
  }

  /// Se busca cuando la persona deja de teclear, no con cada letra: una sola petición por «copa quito».
  void _onSearchChanged(String text) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(AppConstants.searchDebounce.value, () => _explorer.search(text));
  }

  void _openEvent(EventModel event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LeagueDetailPage(event: event, isOwner: false),
      ),
    );
  }

  String _statusLabel(EventStatus status) => switch (status) {
        EventStatus.active => 'mobile.events.status_active'.tr(),
        EventStatus.upcoming => 'mobile.events.status_upcoming'.tr(),
        EventStatus.finished => 'mobile.events.status_finished'.tr(),
        EventStatus.cancelled => 'mobile.events.status_cancelled'.tr(),
      };

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.localizedName),
        actions: [
          IconButton(
            onPressed: _explorer.load,
            icon: const Icon(Icons.refresh),
            tooltip: 'common.retry'.tr(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTeamHeader(),
          _buildSearchField(),
          _buildStatusChips(),
          Expanded(
            child: ListenableBuilder(
              listenable: _explorer,
              builder: (context, _) => _buildResults(),
            ),
          ),
        ],
      ),
    );
  }

  /// Quien tiene equipo elige entre los eventos de su equipo y todos; en «Mi equipo» se dice de cuál equipo son (con varios
  /// equipos) y se puede cambiar desde aquí.
  Widget _buildTeamHeader() {
    return ListenableBuilder(
      listenable: _explorer,
      builder: (context, _) {
        if (!_explorer.hasTeam) return const SizedBox.shrink();
        return Column(
          children: [
            _buildScopeSelector(),
            if (_explorer.scope == EventsScope.myTeam)
              const ActiveTeamPill(
                margin: EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.md, AppSpacing.page, 0),
              ),
          ],
        );
      },
    );
  }

  Widget _buildScopeSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.md, AppSpacing.page, 0),
      child: SegmentedButton<EventsScope>(
        segments: [
          ButtonSegment(
            value: EventsScope.myTeam,
            icon: const Icon(Icons.shield_outlined),
            label: Text('mobile.events.scope_mine'.tr()),
          ),
          ButtonSegment(
            value: EventsScope.all,
            icon: const Icon(Icons.public),
            label: Text('mobile.events.scope_all'.tr()),
          ),
        ],
        selected: {_explorer.scope},
        onSelectionChanged: (selection) => _explorer.selectScope(selection.first),
        showSelectedIcon: false,
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.md, AppSpacing.page, 0),
      child: AppSearchField(
        controller: _searchController,
        hint: 'mobile.events.search_hint'.tr(),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildStatusChips() {
    return ListenableBuilder(
      listenable: _explorer,
      builder: (context, _) => SizedBox(
        height: 58,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: AppSpacing.md),
          scrollDirection: Axis.horizontal,
          children: [
            _buildStatusChip('mobile.events.all'.tr(), null),
            ..._filterableStatuses.map((status) => _buildStatusChip(_statusLabel(status), status)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, EventStatus? status) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(label),
        selected: _explorer.status == status,
        onSelected: (_) => _explorer.selectStatus(status),
      ),
    );
  }

  Widget _buildResults() {
    if (_explorer.loading && _explorer.events.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryLight));
    }
    if (_explorer.error != null && _explorer.events.isEmpty) {
      return ErrorRetry(message: _explorer.error!.tr(), onRetry: _explorer.load);
    }
    if (_explorer.events.isEmpty) return _buildEmpty();

    return RefreshIndicator(
      onRefresh: _explorer.load,
      color: AppColors.primaryLight,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.listBottom),
        itemCount: _explorer.events.length + 1,
        itemBuilder: (context, index) {
          if (index == _explorer.events.length) return _buildListFooter();
          final event = _explorer.events[index];
          return EventCard(
            event: event,
            typeIcon: Icons.emoji_events_outlined,
            onTap: () => _openEvent(event),
          );
        },
      ),
    );
  }

  /// Al final de la lista: el cargando de la página que sigue, o cuántos eventos hay si ya están todos.
  Widget _buildListFooter() {
    if (_explorer.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(color: AppColors.primaryLight, strokeWidth: 2.5)),
      );
    }
    if (_explorer.hasMore) {
      return TextButton(
        onPressed: _explorer.loadMore,
        child: Text('mobile.events.load_more'.tr()),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          'mobile.events.results_count'.tr(namedArgs: {'count': '${_explorer.totalElements}'}),
          style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 12),
        ),
      ),
    );
  }

  /// Sin eventos que mostrar: «sin resultados» si hay una búsqueda o un estado puestos; si no, que el equipo aún no juega
  /// ninguno (con el atajo a todos los eventos) o que no hay eventos.
  Widget _buildEmpty() {
    final isFiltering = _explorer.isFiltering;
    final isTeamWithoutEvents = !isFiltering && _explorer.scope == EventsScope.myTeam;
    final String titleKey;
    final String subtitleKey;
    if (isFiltering) {
      titleKey = 'mobile.events.no_results_title';
      subtitleKey = 'mobile.events.no_results_subtitle';
    } else if (isTeamWithoutEvents) {
      titleKey = 'mobile.events.empty_mine_title';
      subtitleKey = 'mobile.events.empty_mine_subtitle';
    } else {
      titleKey = 'mobile.events.empty_title';
      subtitleKey = 'mobile.events.empty_subtitle';
    }
    return RefreshIndicator(
      onRefresh: _explorer.load,
      color: AppColors.primaryLight,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // Alto mínimo y no fijo: con el botón «Ver todos los eventos» el contenido puede ser más alto que la mitad de la
          // pantalla y entonces debe crecer (la lista se desplaza) en vez de desbordarse.
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height * 0.5),
            child: EmptyState(
              icon: isFiltering ? Icons.filter_list_off : Icons.emoji_events_outlined,
              title: titleKey.tr(),
              subtitle: subtitleKey.tr(),
              onAdd: isTeamWithoutEvents ? () => _explorer.selectScope(EventsScope.all) : null,
              actionLabel: 'mobile.events.see_all'.tr(),
              actionIcon: Icons.public,
            ),
          ),
        ],
      ),
    );
  }
}
