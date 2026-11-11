import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/teams_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/team_model.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/players/domain/enums/category_eligibility_issue.dart';
import 'package:sport_platform/modules/players/presentation/pages/join_team_page.dart';
import 'package:sport_platform/modules/players/presentation/utils/category_refusal.dart';
import 'package:sport_platform/modules/players/presentation/widgets/category_eligibility_notice.dart';
import 'package:sport_platform/modules/teams/domain/team_members.dart';
import 'package:sport_platform/modules/teams/presentation/providers/active_team_notifier.dart';
import 'package:sport_platform/modules/teams/presentation/widgets/team_switcher.dart';
import 'package:sport_platform/modules/teams/presentation/widgets/team_switcher_card.dart';
import 'package:sport_platform/shared/widgets/app_card.dart';
import 'package:sport_platform/shared/widgets/app_snackbar.dart';
import 'package:sport_platform/shared/widgets/confirmation_dialog.dart';
import 'package:sport_platform/shared/widgets/empty_state.dart';
import 'package:sport_platform/shared/widgets/error_retry.dart';
import 'package:sport_platform/shared/widgets/initials_avatar.dart';

class TeamsPage extends StatefulWidget {
  final MenuItemModel item;

  const TeamsPage({super.key, required this.item});

  @override
  State<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends State<TeamsPage> {
  /// El equipo que se ve aquí es el activo de TODA la app: elegirlo en el selector cambia también el inicio, los partidos,
  /// los reportes y los rankings.
  final _activeTeam = getIt<ActiveTeamNotifier>();

  late Future<_TeamsData?> _teamsData;
  bool _isLeaving = false;

  @override
  void initState() {
    super.initState();
    _teamsData = _loadTeamsData();
  }

  /// Lee al jugador y, de cada uno de sus equipos, el equipo y su plantilla, todos a la vez: cambiar de equipo es
  /// instantáneo, sin esperar a otra lectura.
  Future<_TeamsData?> _loadTeamsData() async {
    final player = await getIt<PlayersService>().getCurrent();
    // Aun sin equipos se anota: así la app se entera de que el jugador ya no tiene ninguno (acaba de abandonar el último).
    await _activeTeam.sync(player);
    final memberships = player?.allTeams ?? const <PlayerTeam>[];
    if (player == null || memberships.isEmpty) return null;

    // `allTeams` ya viene del equipo al que entró más recientemente al más antiguo: ese es el orden del selector.
    final sections = await Future.wait(memberships.map(_loadTeamSection));
    final shownSections = sections.whereType<_TeamSection>().toList();
    if (shownSections.isEmpty) return null;

    final data = _TeamsData(player: player, sections: shownSections);
    // Un equipo que ya no existe no se muestra: si era el activo, pasa a serlo el primero que sí.
    if (!data.teamIds.contains(_activeTeam.activeTeamId)) _activeTeam.select(data.teamIds.first);
    return data;
  }

  /// Su equipo por id, no la lista de todos los que la app puede ver. Null si el equipo ya no existe.
  Future<_TeamSection?> _loadTeamSection(PlayerTeam membership) async {
    final results = await Future.wait<dynamic>([
      getIt<TeamsService>().getById(membership.teamId),
      getIt<PlayersService>().getByTeamId(membership.teamId),
    ]);
    final team = results[0] as TeamModel?;
    if (team == null) return null;
    return _TeamSection(
      team: team,
      isCaptain: membership.isCaptain,
      cannotPlay: membership.cannotPlay,
      categoryIssue: membership.categoryIneligibility,
      members: sortCaptainFirst(results[1] as List<PlayerModel>),
    );
  }

  Future<void> _reload() async {
    // Con llaves: un `setState` cuyo callback devuelve el Future (la forma con flecha) falla en modo debug.
    setState(() {
      _teamsData = _loadTeamsData();
    });
    await _teamsData;
  }

  void _selectTeam(String teamId) {
    setState(() => _activeTeam.select(teamId));
  }

  /// El aviso de «no puedes jugar» solo pide datos del perfil: se abre el formulario y, si guardó, se vuelve a leer todo (el
  /// backend juzga de nuevo con los datos nuevos).
  Future<void> _completeProfile() async {
    final saved = await openProfileEditor(context);
    if (saved && mounted) await _reload();
  }

  Future<void> _joinWithCode() async {
    final joined = await JoinTeamPage.open(context);
    if (joined && mounted) await _reload();
  }

  /// Pide confirmación y saca al jugador de ese equipo (los demás se quedan); después la pantalla vuelve a leerse: con
  /// otros equipos muestra los que queden, y sin ninguno queda como la de quien no tiene equipo (con la opción de entrar
  /// con un código).
  Future<void> _leaveTeam(PlayerModel player, _TeamSection section) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'mobile.teams.leave_title'.tr(args: [section.team.name]),
      content: _leaveMessage(isCaptain: section.isCaptain),
      confirmLabel: 'mobile.teams.leave_confirm'.tr(),
      cancelLabel: 'common.cancel'.tr(),
    );
    if (!confirmed || !mounted) return;
    setState(() => _isLeaving = true);
    try {
      await getIt<PlayersService>().removeFromTeam(player.id, teamId: section.team.id);
    } catch (_) {
      if (mounted) {
        setState(() => _isLeaving = false);
        AppSnackbar.error(context, 'mobile.teams.leave_error'.tr());
      }
      return;
    }
    if (!mounted) return;
    setState(() => _isLeaving = false);
    AppSnackbar.success(context, 'mobile.teams.leave_success'.tr());
    await _reload();
  }

  /// Quien es capitán de ese equipo además pierde la capitanía al salir, y lo debe saber antes de confirmar.
  String _leaveMessage({required bool isCaptain}) {
    final message = 'mobile.teams.leave_message'.tr();
    return isCaptain ? '$message\n\n${'mobile.teams.leave_captain_note'.tr()}' : message;
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.localizedName),
        actions: [
          IconButton(
            onPressed: _reload,
            tooltip: 'common.retry'.tr(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<_TeamsData?>(
        future: _teamsData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorRetry(
              message: 'mobile.teams.load_error'.tr(),
              onRetry: _reload,
            );
          }
          final data = snapshot.data;
          if (data == null) {
            return EmptyState(
              icon: Icons.groups_outlined,
              title: 'mobile.teams.empty_title'.tr(),
              subtitle: 'mobile.teams.no_membership'.tr(),
              // Sin equipo: se puede entrar con el código que da su administrador, sin esperar una invitación.
              onAdd: _joinWithCode,
              actionLabel: 'join_team.title'.tr(),
              actionIcon: Icons.vpn_key_outlined,
            );
          }
          return _buildTeams(data);
        },
      ),
    );
  }

  /// El selector de equipos y, debajo, el detalle del elegido.
  Widget _buildTeams(_TeamsData data) {
    final selected = data.sectionOf(_activeTeam.activeTeamId);
    return RefreshIndicator(
      onRefresh: _reload,
      color: AppColors.primaryLight,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        // Sin margen lateral: el carrusel llega de borde a borde (así se asoma el equipo vecino) y cada bloque pone el suyo.
        padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.listBottom),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_title(data), style: AppTextStyles.sectionTitle),
                // Con varios equipos, elegir uno cambia lo que ve toda la app: se dice aquí, donde se elige.
                if (data.sections.length > 1) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text('mobile.teams.active_hint'.tr(), style: AppTextStyles.caption),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TeamSwitcher(
            items: data.switcherItems,
            selectedTeamId: selected.team.id,
            onSelected: _selectTeam,
          ),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: _TeamDetailTransition(
              child: _TeamDetail(
                key: ValueKey('team-detail-${selected.team.id}'),
                section: selected,
                isLeaving: _isLeaving,
                onLeave: () => _leaveTeam(data.player, selected),
                onCompleteProfile: _completeProfile,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _title(_TeamsData data) => data.sections.length > 1
      ? 'mobile.teams.your_teams'.tr(namedArgs: {'count': '${data.sections.length}'})
      : 'mobile.teams.your_team'.tr();
}

/// Lo que muestra la pantalla: el jugador de la cuenta y cada uno de sus equipos, del último al que entró al más antiguo.
class _TeamsData {
  /// El jugador de la cuenta (uno de los jugadores de cada equipo): quien puede abandonarlos.
  final PlayerModel player;
  final List<_TeamSection> sections;

  const _TeamsData({required this.player, required this.sections});

  List<String> get teamIds => [for (final section in sections) section.team.id];

  List<TeamSwitcherItem> get switcherItems => [
        for (final section in sections)
          TeamSwitcherItem(
            teamId: section.team.id,
            name: section.team.name,
            logoUrl: section.team.logoUrl,
            playerCount: section.members.length,
            isCaptain: section.isCaptain,
          ),
      ];

  /// El equipo con ese id; si no está (no debería pasar), el primero.
  _TeamSection sectionOf(String? teamId) =>
      sections.firstWhere((section) => section.team.id == teamId, orElse: () => sections.first);
}

/// Un equipo del jugador con su plantilla.
class _TeamSection {
  final TeamModel team;

  /// Si el jugador es capitán de ESTE equipo (puede serlo de uno y de otro no).
  final bool isCaptain;

  /// El jugador está en este equipo pero la categoría no lo deja jugar (género, edad o perfil incompleto), y por qué.
  final bool cannotPlay;
  final CategoryEligibilityIssue? categoryIssue;
  final List<PlayerModel> members;

  const _TeamSection({
    required this.team,
    required this.isCaptain,
    required this.members,
    this.cannotPlay = false,
    this.categoryIssue,
  });
}

/// Al cambiar de equipo, el detalle anterior se desvanece y el nuevo entra con un leve ascenso; la altura se ajusta
/// suave si las dos plantillas miden distinto, para que lo de abajo no salte.
class _TeamDetailTransition extends StatelessWidget {
  final Widget child;

  const _TeamDetailTransition({required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(animation),
            child: child,
          ),
        ),
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, ?current],
        ),
        child: child,
      ),
    );
  }
}

/// Lo del equipo elegido que no cabe en su tarjeta: sus jugadores y la acción de abandonarlo.
class _TeamDetail extends StatelessWidget {
  final _TeamSection section;
  final bool isLeaving;
  final VoidCallback onLeave;
  final VoidCallback onCompleteProfile;

  const _TeamDetail({
    super.key,
    required this.section,
    required this.isLeaving,
    required this.onLeave,
    required this.onCompleteProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sigue en la plantilla pero la categoría no lo deja jugar: se le dice por qué y qué puede hacer.
        if (section.cannotPlay) ...[
          CategoryEligibilityNotice(issue: section.categoryIssue, onCompleteProfile: onCompleteProfile),
          const SizedBox(height: AppSpacing.xl),
        ],
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Text('mobile.teams.players'.tr(), style: AppTextStyles.sectionTitle),
        ),
        if (section.members.isEmpty)
          EmptyState(
            icon: Icons.person_search_outlined,
            title: 'mobile.teams.players_empty'.tr(),
            subtitle: '',
          )
        else
          ...section.members.map(_PlayerTile.new),
        const SizedBox(height: AppSpacing.xxl),
        _LeaveTeamButton(isBusy: isLeaving, onPressed: onLeave),
      ],
    );
  }
}

class _PlayerTile extends StatelessWidget {
  final PlayerModel player;

  const _PlayerTile(this.player);

  @override
  Widget build(BuildContext context) {
    final name = player.fullName.trim().isEmpty
        ? player.email
        : player.fullName.trim();
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          InitialsAvatar(name: name, logoUrl: player.profilePhotoUrl, size: 42),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.cardTitle),
                if (player.email.isNotEmpty && player.email != name) ...[
                  const SizedBox(height: 2),
                  Text(player.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption),
                ],
              ],
            ),
          ),
          if (player.isCaptain) ...[
            const SizedBox(width: AppSpacing.sm),
            const _CaptainBadge(),
          ],
        ],
      ),
    );
  }
}

/// La acción de salir del equipo: va al final de la pantalla y en rojo porque se deshace solo con un código o una
/// invitación.
class _LeaveTeamButton extends StatelessWidget {
  final bool isBusy;
  final VoidCallback onPressed;

  const _LeaveTeamButton({required this.isBusy, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isBusy ? null : onPressed,
      icon: const Icon(Icons.logout, size: 18),
      label: Text('mobile.teams.leave'.tr()),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: const BorderSide(color: AppColors.error),
      ),
    );
  }
}

/// La insignia del capitán de su equipo.
class _CaptainBadge extends StatelessWidget {
  const _CaptainBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning),
      ),
      child: Text(
        'mobile.teams.captain'.tr(),
        style: const TextStyle(
          color: AppColors.warningLight,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
