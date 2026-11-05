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
import 'package:sport_platform/modules/players/presentation/pages/join_team_page.dart';
import 'package:sport_platform/modules/teams/domain/team_members.dart';
import 'package:sport_platform/shared/widgets/app_card.dart';
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
  late Future<_TeamData?> _teamData;

  @override
  void initState() {
    super.initState();
    _teamData = _loadTeamData();
  }

  Future<_TeamData?> _loadTeamData() async {
    final player = await getIt<PlayersService>().getCurrent();
    final teamId = player?.teamId;
    if (player == null || teamId == null || teamId.isEmpty) return null;

    // Su equipo por id, no la lista de todos los que la app puede ver.
    final results = await Future.wait<dynamic>([
      getIt<TeamsService>().getById(teamId),
      getIt<PlayersService>().getByTeamId(teamId),
    ]);
    final team = results[0] as TeamModel?;
    if (team == null) return null;
    return _TeamData(
      team: team,
      members: sortCaptainFirst(results[1] as List<PlayerModel>),
    );
  }

  Future<void> _reload() async {
    setState(() => _teamData = _loadTeamData());
    await _teamData;
  }

  Future<void> _joinWithCode() async {
    final joined = await JoinTeamPage.open(context);
    if (joined && mounted) await _reload();
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
      body: FutureBuilder<_TeamData?>(
        future: _teamData,
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
          return RefreshIndicator(
            onRefresh: _reload,
            color: AppColors.primaryLight,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.lg,
                AppSpacing.page,
                AppSpacing.listBottom,
              ),
              children: [
                _TeamHeader(team: data.team, playerCount: data.members.length),
                const SizedBox(height: AppSpacing.xxl),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text('mobile.teams.players'.tr(), style: AppTextStyles.sectionTitle),
                ),
                if (data.members.isEmpty)
                  EmptyState(
                    icon: Icons.person_search_outlined,
                    title: 'mobile.teams.players_empty'.tr(),
                    subtitle: '',
                  )
                else
                  ...data.members.map(_PlayerTile.new),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TeamData {
  final TeamModel team;
  final List<PlayerModel> members;

  const _TeamData({required this.team, required this.members});
}

class _TeamHeader extends StatelessWidget {
  final TeamModel team;
  final int playerCount;

  const _TeamHeader({required this.team, required this.playerCount});

  @override
  Widget build(BuildContext context) {
    final count = 'mobile.teams.players_count'.tr(namedArgs: {'count': '$playerCount'});
    return AppCard(
      accent: AppColors.primaryLight,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: [
          InitialsAvatar(name: team.name, logoUrl: team.logoUrl, size: 68),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.pageTitle,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${'mobile.teams.your_team'.tr()} · $count',
                  style: AppTextStyles.bodyMuted,
                ),
              ],
            ),
          ),
        ],
      ),
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
