import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/teams_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/team_model.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/shared/widgets/empty_state.dart';
import 'package:sport_platform/shared/widgets/error_retry.dart';

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

    final results = await Future.wait<dynamic>([
      getIt<TeamsService>().getAll(),
      getIt<PlayersService>().getByTeamId(teamId),
    ]);
    final teams = results[0] as List<TeamModel>;
    TeamModel? team;
    for (final value in teams) {
      if (value.id == teamId) {
        team = value;
        break;
      }
    }
    if (team == null) return null;
    return _TeamData(team: team, members: results[1] as List<PlayerModel>);
  }

  Future<void> _reload() async {
    setState(() => _teamData = _loadTeamData());
    await _teamData;
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Scaffold(
      backgroundColor: AppColors.backgroundEnd,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: Text(
          widget.item.localizedName,
          style: const TextStyle(color: AppColors.white),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
        actions: [
          IconButton(
            onPressed: _reload,
            tooltip: 'common.retry'.tr(),
            icon: const Icon(Icons.refresh, color: AppColors.white),
          ),
        ],
      ),
      body: FutureBuilder<_TeamData?>(
        future: _teamData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryLight),
            );
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
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            color: AppColors.primaryLight,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _TeamHeader(team: data.team),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'mobile.teams.players'.tr(),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${data.members.length}',
                      style: const TextStyle(color: AppColors.whiteSubtle),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
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

  const _TeamHeader({required this.team});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: team.logoUrl?.isNotEmpty == true
                ? ClipOval(
                    child: Image.network(
                      team.logoUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.shield_outlined,
                        color: AppColors.primaryLight,
                        size: 28,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.shield_outlined,
                    color: AppColors.primaryLight,
                    size: 28,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'mobile.teams.your_team'.tr(),
                  style: const TextStyle(color: AppColors.whiteSubtle),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
          child: player.profilePhotoUrl?.isNotEmpty == true
              ? ClipOval(
                  child: Image.network(
                    player.profilePhotoUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.person_outline,
                      color: AppColors.primaryLight,
                    ),
                  ),
                )
              : const Icon(Icons.person_outline, color: AppColors.primaryLight),
        ),
        title: Text(name, style: const TextStyle(color: AppColors.white)),
        subtitle: player.email.isEmpty
            ? null
            : Text(
                player.email,
                style: const TextStyle(color: AppColors.whiteSubtle),
              ),
      ),
    );
  }
}
