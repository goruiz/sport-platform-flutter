import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/users/presentation/providers/profile_summary_notifier.dart';
import 'package:sport_platform/modules/users/presentation/widgets/profile_section.dart';
import 'package:sport_platform/shared/widgets/skeleton_box.dart';

/// «Mi equipo» en el perfil: a qué equipo pertenece el jugador y qué rol tiene en él (jugador o capitán). Quien juega en
/// varios (uno por organización) los ve todos, cada uno con su rol: puede ser capitán de uno y no de otro.
class ProfileTeamSection extends StatelessWidget {
  final SummaryStatus status;
  final PlayerModel? player;
  final VoidCallback onRetry;

  const ProfileTeamSection({
    super.key,
    required this.status,
    required this.player,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    context.locale;
    final playsForSeveral = (player?.allTeams.length ?? 0) > 1;
    return ProfileSection(
      title: (playsForSeveral ? 'mobile.profile.section_teams' : 'mobile.profile.section_team').tr(),
      children: switch (status) {
        SummaryStatus.loading => const [_LoadingRow()],
        SummaryStatus.failed => [ProfileMessageRow(message: 'mobile.teams.load_error'.tr(), onRetry: onRetry)],
        SummaryStatus.ready => _buildTeamRows(),
      },
    );
  }

  List<Widget> _buildTeamRows() {
    final teams = player?.allTeams ?? const <PlayerTeam>[];
    if (teams.isEmpty) {
      return [ProfileMessageRow(message: 'mobile.profile.no_team'.tr())];
    }
    if (teams.length > 1) {
      // Una fila por equipo: el nombre y, a su lado, el rol que tiene en ESE equipo.
      return [for (final team in teams) ProfileInfoRow(label: team.teamName, value: _roleLabelOf(team))];
    }
    final team = teams.first;
    return [
      ProfileInfoRow(label: 'mobile.profile.team'.tr(), value: team.teamName),
      ProfileInfoRow(label: 'mobile.profile.team_role'.tr(), value: _roleLabelOf(team)),
    ];
  }
}

/// El rol que el jugador tiene en un equipo: capitán o jugador.
String _roleLabelOf(PlayerTeam team) =>
    (team.isCaptain ? 'mobile.profile.role_captain' : 'mobile.profile.role_player').tr();

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: SkeletonBox(height: 40),
    );
  }
}
