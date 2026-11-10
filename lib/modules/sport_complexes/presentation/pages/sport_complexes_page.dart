import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/modules/courts/presentation/pages/court_detail_page.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/court_model.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/sport_complexes/domain/complex_overview.dart';
import 'package:sport_platform/modules/sport_complexes/presentation/pages/sport_complex_detail_page.dart';
import 'package:sport_platform/modules/sport_complexes/presentation/providers/sport_complexes_notifier.dart';
import 'package:sport_platform/modules/sport_complexes/presentation/widgets/complex_section_card.dart';
import 'package:sport_platform/modules/teams/presentation/widgets/active_team_pill.dart';
import 'package:sport_platform/shared/widgets/app_search_field.dart';
import 'package:sport_platform/shared/widgets/empty_state.dart';
import 'package:sport_platform/shared/widgets/error_retry.dart';

/// Los complejos deportivos con sus canchas dentro, en una sola pantalla: por defecto los complejos donde se juegan los
/// eventos del equipo activo del jugador (el que eligió en «Equipo»; con varios equipos se cambia desde aquí) o, a
/// elección, todos los de su organización. Un complejo se abre para ver su mapa y una cancha, para ver sus horarios.
class SportComplexesPage extends StatefulWidget {
  final MenuItemModel item;

  const SportComplexesPage({super.key, required this.item});

  @override
  State<SportComplexesPage> createState() => _SportComplexesPageState();
}

class _SportComplexesPageState extends State<SportComplexesPage> {
  late final SportComplexesNotifier _notifier;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _notifier = SportComplexesNotifier(
      complexesService: getIt(),
      courtsService: getIt(),
      teamEventsService: getIt(),
      playersService: getIt(),
      activeTeam: getIt(),
    )..load();
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  void _openComplex(ComplexOverview overview) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SportComplexDetailPage(overview: overview)),
    );
  }

  /// [overview] es el complejo de la cancha, para ofrecer desde ella el enlace a su mapa; null si no tiene complejo.
  void _openCourt(CourtModel court, ComplexOverview? overview) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CourtDetailPage(court: court, complex: overview)),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.localizedName),
        actions: [
          IconButton(
            onPressed: _notifier.load,
            tooltip: 'common.retry'.tr(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTeamHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.md, AppSpacing.page, AppSpacing.sm),
            child: AppSearchField(
              hint: 'mobile.complexes.search_hint'.tr(),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: ListenableBuilder(listenable: _notifier, builder: (context, _) => _buildResults()),
          ),
        ],
      ),
    );
  }

  /// Quien tiene equipo elige entre los complejos de los eventos de su equipo y todos; en «Mi equipo» se dice de cuál
  /// equipo son (con varios equipos) y se puede cambiar desde aquí.
  Widget _buildTeamHeader() {
    return ListenableBuilder(
      listenable: _notifier,
      builder: (context, _) {
        if (!_notifier.hasTeam) return const SizedBox.shrink();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.md, AppSpacing.page, 0),
              child: SegmentedButton<ComplexesScope>(
                segments: [
                  ButtonSegment(
                    value: ComplexesScope.myTeam,
                    icon: const Icon(Icons.shield_outlined),
                    label: Text('mobile.complexes.scope_mine'.tr()),
                  ),
                  ButtonSegment(
                    value: ComplexesScope.all,
                    icon: const Icon(Icons.public),
                    label: Text('mobile.complexes.scope_all'.tr()),
                  ),
                ],
                selected: {_notifier.scope},
                onSelectionChanged: (selection) => _notifier.selectScope(selection.first),
                showSelectedIcon: false,
              ),
            ),
            if (_notifier.scope == ComplexesScope.myTeam)
              const ActiveTeamPill(
                margin: EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.md, AppSpacing.page, 0),
              ),
          ],
        );
      },
    );
  }

  Widget _buildResults() {
    if (_notifier.loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryLight));
    }
    final error = _notifier.error;
    if (error != null) return ErrorRetry(message: error.tr(), onRetry: _notifier.load);

    final overviews = _notifier.overviews;
    final looseCourts = _notifier.courtsWithoutComplex;
    if (overviews.isEmpty && looseCourts.isEmpty) return _buildNothingToShow();

    final visibleOverviews = filterComplexOverviews(overviews, _query);
    final visibleLooseCourts = filterCourtsByQuery(looseCourts, _query);
    if (visibleOverviews.isEmpty && visibleLooseCourts.isEmpty) {
      return _scrollableEmptyState(
        EmptyState(
          icon: Icons.search_off,
          title: 'mobile.complexes.filtered_empty_title'.tr(),
          subtitle: 'mobile.complexes.filtered_empty_subtitle'.tr(),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _notifier.load,
      color: AppColors.primaryLight,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.listBottom),
        children: [
          for (final overview in visibleOverviews) _buildComplexCard(overview),
          if (visibleLooseCourts.isNotEmpty)
            ComplexSectionCard(
              icon: Icons.location_off_outlined,
              title: 'mobile.complexes.courts_without_complex'.tr(),
              courts: visibleLooseCourts,
              onTapCourt: (court) => _openCourt(court, null),
            ),
        ],
      ),
    );
  }

  Widget _buildComplexCard(ComplexOverview overview) {
    final complex = overview.complex;
    return ComplexSectionCard(
      icon: Icons.stadium_outlined,
      title: complex.name,
      location: complex.location,
      note: complex.hasMapPosition ? null : 'mobile.complexes.no_location'.tr(),
      onTapHeader: () => _openComplex(overview),
      courts: overview.courts,
      onTapCourt: (court) => _openCourt(court, overview),
    );
  }

  /// No hay complejos en este alcance: si es «Mi equipo», que ningún evento del equipo tiene asignado dónde se juega (con
  /// el atajo a todos los complejos); si es «Todos», que la organización aún no tiene.
  Widget _buildNothingToShow() {
    final isTeamScope = _notifier.scope == ComplexesScope.myTeam;
    return _scrollableEmptyState(
      EmptyState(
        icon: Icons.stadium_outlined,
        title: (isTeamScope ? 'mobile.complexes.empty_mine_title' : 'mobile.complexes.empty_title').tr(),
        subtitle: (isTeamScope ? 'mobile.complexes.empty_mine_subtitle' : 'mobile.complexes.empty_subtitle').tr(),
        onAdd: isTeamScope ? () => _notifier.selectScope(ComplexesScope.all) : null,
        actionLabel: 'mobile.complexes.see_all'.tr(),
        actionIcon: Icons.public,
      ),
    );
  }

  /// Con alto mínimo y no fijo: si el contenido es más alto que la pantalla (con el botón de ver todos, en una pantalla
  /// baja) la lista se desplaza en vez de desbordarse, y tirar hacia abajo también actualiza.
  Widget _scrollableEmptyState(Widget emptyState) {
    return RefreshIndicator(
      onRefresh: _notifier.load,
      color: AppColors.primaryLight,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height * 0.5),
            child: emptyState,
          ),
        ],
      ),
    );
  }
}
