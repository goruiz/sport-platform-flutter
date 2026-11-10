import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_input_decoration.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/standings_tab.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/events/shared/data/datasource/events_search_service.dart';
import 'package:sport_platform/modules/events/shared/data/datasource/team_events_service.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/events/shared/presentation/widgets/championship_tab.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/rankings/data/datasource/player_stats_service.dart';
import 'package:sport_platform/modules/rankings/data/models/player_stats_model.dart';
import 'package:sport_platform/modules/rankings/domain/leaderboards.dart';
import 'package:sport_platform/modules/rankings/domain/my_stats.dart';
import 'package:sport_platform/modules/rankings/presentation/widgets/leaderboard_list.dart';
import 'package:sport_platform/modules/rankings/presentation/widgets/my_stats_card.dart';
import 'package:sport_platform/modules/teams/presentation/providers/active_team_notifier.dart';
import 'package:sport_platform/modules/teams/presentation/widgets/active_team_pill.dart';
import 'package:sport_platform/shared/widgets/empty_state.dart';
import 'package:sport_platform/shared/widgets/error_retry.dart';

/// Las posiciones y los líderes (goles, asistencias, tarjetas) del evento que el usuario elija entre los de su equipo
/// activo (quien aún no tiene equipo elige entre los que ve). Al cambiar de equipo se ofrecen los eventos del nuevo.
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
  final _activeTeam = getIt<ActiveTeamNotifier>();
  late Future<List<EventModel>> _eventsFuture;
  Future<List<PlayerStatsModel>>? _statsFuture;
  EventModel? _selectedEvent;
  PlayerModel? _currentPlayer;
  LeaderboardScope _scope = LeaderboardScope.event;

  /// El equipo activo cuyos eventos se leyeron (o se están leyendo): lo que se compara para saber si cambió. Null si el
  /// jugador no tiene equipo.
  String? _watchedTeamId;

  /// Cuenta las lecturas de eventos: la que ya no es la última (el jugador volvió a cambiar de equipo) no decide el evento.
  int _eventsLoadCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
    _activeTeam.addListener(_onActiveTeamChanged);
    _eventsFuture = _loadEvents();
  }

  @override
  void dispose() {
    _activeTeam.removeListener(_onActiveTeamChanged);
    _tabController.dispose();
    super.dispose();
  }

  /// El jugador eligió ver otro de sus equipos: se ofrecen los eventos del nuevo y «Mi equipo» pasa a ser ese. Los avisos
  /// que no cambian el equipo activo (la lista de equipos, por ejemplo) solo vuelven a filtrar «Mi equipo»: las
  /// estadísticas del evento son las mismas.
  void _onActiveTeamChanged() {
    if (!mounted) return;
    final teamChanged = _watchedTeamId != null && _activeTeam.activeTeamId != _watchedTeamId;
    setState(() {
      if (teamChanged) _eventsFuture = _loadEventsOfActiveTeam();
    });
  }

  Future<List<EventModel>> _loadEvents() async {
    _currentPlayer = await _readCurrentPlayer();
    return _loadEventsOfActiveTeam();
  }

  /// Los eventos entre los que se elige: los del equipo activo, y quien no tiene equipo ve los primeros que ordena el
  /// backend (lo que está en curso va primero), no todos los de la plataforma.
  Future<List<EventModel>> _loadEventsOfActiveTeam() async {
    final loadId = ++_eventsLoadCount;
    final activeTeamId = _activeTeam.activeTeamId;
    _watchedTeamId = activeTeamId;
    final events = activeTeamId == null
        ? (await getIt<EventsSearchService>().search()).events
        : await getIt<TeamEventsService>().getOfTeam(activeTeamId);
    if (loadId == _eventsLoadCount) _chooseEvent(events);
    return events;
  }

  /// Deja elegido el evento de antes si sigue entre [events] y, si no, el de apertura; sin eventos no queda ninguno (ni
  /// las estadísticas del evento del equipo anterior).
  void _chooseEvent(List<EventModel> events) {
    final event = resolveSelectedEvent(events, _selectedEvent?.id);
    if (event == null) {
      _selectedEvent = null;
      _statsFuture = null;
    } else {
      _selectEvent(event);
    }
  }

  /// El jugador de la cuenta, para mostrarle sus propias estadísticas y el ranking de su equipo; sin él (o si falla)
  /// solo se omiten esa tarjeta y el selector de alcance. Sus equipos se anotan en [ActiveTeamNotifier], que dice cuál
  /// de ellos es el activo.
  Future<PlayerModel?> _readCurrentPlayer() async {
    try {
      final player = await getIt<PlayersService>().getCurrent();
      await _activeTeam.sync(player);
      return player;
    } catch (_) {
      return null;
    }
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
      appBar: AppBar(
        title: Text(widget.item.localizedName),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: 'rankings.standings'.tr()),
            for (final kind in LeaderboardKind.values) Tab(text: kind.translationKey.tr()),
          ],
        ),
      ),
      body: Column(
        children: [
          // Fuera de la lectura de eventos: un equipo sin eventos (o una lectura que falla) no debe dejar al jugador sin
          // poder volver a elegir otro.
          const ActiveTeamPill(margin: EdgeInsets.fromLTRB(16, 16, 16, 0)),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return FutureBuilder<List<EventModel>>(
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
            onRetry: () => setState(() {
              _eventsFuture = _loadEvents();
            }),
          );
        }
        final events = snapshot.data ?? const <EventModel>[];
        final selectedEvent = _selectedEvent;
        if (events.isEmpty || selectedEvent == null) return _buildNoEvents();
        return Column(
          children: [
            _buildEventSelector(events),
            _buildMyStats(),
            Expanded(child: _buildTabs(selectedEvent)),
          ],
        );
      },
    );
  }

  /// Sin eventos que mostrar: si el jugador tiene equipo es que el suyo aún no juega ninguno; si no, que no hay eventos.
  Widget _buildNoEvents() {
    final hasTeam = _activeTeam.activeTeamId != null;
    return EmptyState(
      icon: Icons.emoji_events_outlined,
      title: (hasTeam ? 'rankings.no_team_events_title' : 'rankings.no_events_title').tr(),
      subtitle: (hasTeam ? 'rankings.no_team_events_subtitle' : 'rankings.no_events_subtitle').tr(),
    );
  }

  /// Lo que hizo el propio jugador en el evento; no se dibuja nada mientras carga, si falla o si no tiene nada ahí.
  Widget _buildMyStats() {
    return FutureBuilder<List<PlayerStatsModel>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        final mine = findPlayerStats(snapshot.data ?? const [], _currentPlayer?.id);
        return mine == null ? const SizedBox.shrink() : MyStatsCard(stats: mine);
      },
    );
  }

  Widget _buildEventSelector(List<EventModel> events) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
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
          return _buildLeaderboard(kind, snapshot.data ?? const []);
        },
      );
    }).toList();
  }

  /// El listado, con el selector «Todo el evento / Mi equipo» encima para quien tiene equipo. «Mi equipo» abarca a los
  /// compañeros del equipo activo, no a los de todos sus equipos.
  Widget _buildLeaderboard(LeaderboardKind kind, List<PlayerStatsModel> stats) {
    final activeTeamId = _activeTeam.activeTeamId;
    final teamIds = activeTeamId == null ? const <String>{} : {activeTeamId};
    final hasTeam = teamIds.isNotEmpty;
    final isTeamScope = _scope == LeaderboardScope.myTeam;
    return Column(
      children: [
        if (hasTeam) _buildScopeSelector(),
        Expanded(
          child: LeaderboardList(
            stats: filterStatsByScope(stats, _scope, teamIds),
            kind: kind,
            onRefresh: _reloadStats,
            highlightPlayerId: _currentPlayer?.id,
            emptySubtitleKey: isTeamScope ? 'rankings.empty_team_subtitle' : 'rankings.empty_subtitle',
          ),
        ),
      ],
    );
  }

  Widget _buildScopeSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SegmentedButton<LeaderboardScope>(
        segments: [
          for (final scope in LeaderboardScope.values)
            ButtonSegment(
              value: scope,
              icon: Icon(_iconOf(scope)),
              label: Text(scope.translationKey.tr()),
            ),
        ],
        selected: {_scope},
        onSelectionChanged: (selection) => setState(() => _scope = selection.first),
        showSelectedIcon: false,
      ),
    );
  }

  IconData _iconOf(LeaderboardScope scope) => switch (scope) {
        LeaderboardScope.event => Icons.public,
        LeaderboardScope.myTeam => Icons.shield_outlined,
      };
}
