import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/core/constants/locale_keys.g.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/rankings/data/models/player_stats_model.dart';
import 'package:sport_platform/modules/rankings/domain/leaderboards.dart';
import 'package:sport_platform/shared/widgets/empty_state.dart';

/// Un listado de jugadores (goleadores, asistentes o tarjetas) de un evento, de más a menos.
class LeaderboardList extends StatelessWidget {
  final List<PlayerStatsModel> stats;
  final LeaderboardKind kind;
  final Future<void> Function() onRefresh;

  /// El jugador de la cuenta: su fila se resalta para compararse con los demás de un vistazo.
  final String? highlightPlayerId;

  /// Qué se le dice cuando el listado está vacío; cambia si se mira solo a su equipo.
  final String emptySubtitleKey;

  const LeaderboardList({
    super.key,
    required this.stats,
    required this.kind,
    required this.onRefresh,
    this.highlightPlayerId,
    this.emptySubtitleKey = LocaleKeys.rankings_empty_subtitle,
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
                    title: LocaleKeys.rankings_empty_title.tr(),
                    subtitle: emptySubtitleKey.tr(),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxxl),
              itemCount: leaders.length,
              itemBuilder: (context, index) => _LeaderTile(
                rank: index + 1,
                player: leaders[index],
                kind: kind,
                isCurrentPlayer: leaders[index].playerId == highlightPlayerId,
              ),
            ),
    );
  }
}

class _LeaderTile extends StatelessWidget {
  final int rank;
  final PlayerStatsModel player;
  final LeaderboardKind kind;
  final bool isCurrentPlayer;

  const _LeaderTile({
    required this.rank,
    required this.player,
    required this.kind,
    required this.isCurrentPlayer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: isCurrentPlayer ? AppColors.primaryLight.withValues(alpha: 0.12) : AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppRadius.compact),
        border: Border.all(color: isCurrentPlayer ? AppColors.primaryLight : AppColors.inputBorder),
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
                  _displayName,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (player.teamName != null)
                  Text(
                    player.teamName!,
                    style: AppTextStyles.footnote,
                  ),
              ],
            ),
          ),
          if (kind == LeaderboardKind.cards) ..._cardCounters() else _counter('${kind.valueOf(player)}'),
        ],
      ),
    );
  }

  /// El nombre del jugador y, si es quien mira, «(Tú)» para encontrarse sin leer toda la lista.
  String get _displayName {
    final name = player.playerName ?? LocaleKeys.match_detail_unknown_player.tr();
    return isCurrentPlayer ? '$name (${LocaleKeys.rankings_you.tr()})' : name;
  }

  Color get _rankColor => switch (rank) {
        1 => AppColors.podiumGold,
        2 => AppColors.podiumSilver,
        3 => AppColors.podiumBronze,
        _ => AppColors.whiteSubtle,
      };

  List<Widget> _cardCounters() => [
        _cardCounter(player.yellowCards, AppColors.cardYellow),
        const SizedBox(width: AppSpacing.snug),
        _cardCounter(player.redCards, AppColors.cardRed),
      ];

  Widget _cardCounter(int count, Color color) => Row(
        children: [
          Icon(Icons.square_rounded, color: color, size: 16),
          const SizedBox(width: AppSpacing.xs),
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
