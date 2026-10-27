import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/rankings/data/models/player_stats_model.dart';
import 'package:sport_platform/modules/rankings/domain/leaderboards.dart';
import 'package:sport_platform/shared/widgets/empty_state.dart';

/// Un listado de jugadores (goleadores, asistentes o tarjetas) de un evento, de más a menos.
class LeaderboardList extends StatelessWidget {
  final List<PlayerStatsModel> stats;
  final LeaderboardKind kind;
  final Future<void> Function() onRefresh;

  const LeaderboardList({
    super.key,
    required this.stats,
    required this.kind,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final leaders = buildLeaderboard(stats, kind);
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primaryLight,
      child: leaders.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.5,
                  child: EmptyState(
                    icon: Icons.leaderboard_outlined,
                    title: 'rankings.empty_title'.tr(),
                    subtitle: 'rankings.empty_subtitle'.tr(),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: leaders.length,
              itemBuilder: (context, index) => _LeaderTile(
                rank: index + 1,
                player: leaders[index],
                kind: kind,
              ),
            ),
    );
  }
}

class _LeaderTile extends StatelessWidget {
  final int rank;
  final PlayerStatsModel player;
  final LeaderboardKind kind;

  const _LeaderTile({required this.rank, required this.player, required this.kind});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '$rank',
              style: TextStyle(
                color: _rankColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.playerName ?? 'match_detail.unknown_player'.tr(),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (player.teamName != null)
                  Text(
                    player.teamName!,
                    style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 12),
                  ),
              ],
            ),
          ),
          if (kind == LeaderboardKind.cards) ..._cardCounters() else _counter('${kind.valueOf(player)}'),
        ],
      ),
    );
  }

  Color get _rankColor => switch (rank) {
        1 => AppColors.podiumGold,
        2 => AppColors.podiumSilver,
        3 => AppColors.podiumBronze,
        _ => AppColors.whiteSubtle,
      };

  List<Widget> _cardCounters() => [
        _cardCounter(player.yellowCards, AppColors.cardYellow),
        const SizedBox(width: 10),
        _cardCounter(player.redCards, AppColors.cardRed),
      ];

  Widget _cardCounter(int count, Color color) => Row(
        children: [
          Icon(Icons.square_rounded, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );

  Widget _counter(String value) => Text(
        value,
        style: const TextStyle(
          color: AppColors.primaryLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      );
}
