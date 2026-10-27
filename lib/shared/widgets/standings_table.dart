import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';

/// Una fila de la tabla de posiciones, ya lista para dibujar.
class StandingsTableRow {
  final int position;
  final String teamName;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalDifference;
  final int points;

  const StandingsTableRow({
    required this.position,
    required this.teamName,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    this.goalDifference = 0,
    required this.points,
  });
}

/// Tabla de posiciones (PJ, G, E, P, Pts y, si se pide, DG). Las primeras [advancingRows] filas se
/// sombrean: son las que pasan a la siguiente fase.
class StandingsTable extends StatelessWidget {
  final List<StandingsTableRow> rows;
  final int advancingRows;
  final bool showGoalDifference;

  const StandingsTable({
    super.key,
    required this.rows,
    this.advancingRows = 0,
    this.showGoalDifference = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          _buildHeader(),
          ...rows.map(_buildRow),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.primaryDark,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Row(
        children: [
          const _HeaderCell('#', width: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'leagues.standings_col_team'.tr(),
              style: const TextStyle(
                color: AppColors.whiteSubtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          _HeaderCell('leagues.standings_col_played'.tr(), width: 30),
          _HeaderCell('leagues.standings_col_won'.tr(), width: 28),
          _HeaderCell('leagues.standings_col_drawn'.tr(), width: 28),
          _HeaderCell('leagues.standings_col_lost'.tr(), width: 28),
          if (showGoalDifference)
            _HeaderCell('leagues.standings_col_gd'.tr(), width: 32),
          _HeaderCell(
            'leagues.standings_col_pts'.tr(),
            width: 36,
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(StandingsTableRow row) {
    final isTop3 = row.position <= 3;
    final advances = row.position <= advancingRows;
    return Container(
      decoration: BoxDecoration(
        color: advances
            ? AppColors.primaryLight.withValues(alpha: 0.12)
            : AppColors.sheetBackground,
        border: const Border(
          bottom: BorderSide(color: AppColors.inputBorder, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
      child: Row(
        children: [
          _PositionBadge(position: row.position),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              row.teamName,
              style: TextStyle(
                color: isTop3 ? AppColors.white : AppColors.whiteSubtle,
                fontSize: 13,
                fontWeight: isTop3 ? FontWeight.w600 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _DataCell('${row.played}', width: 30, color: AppColors.whiteSubtle),
          _DataCell('${row.won}', width: 28, color: AppColors.success),
          _DataCell('${row.drawn}', width: 28, color: AppColors.whiteSubtle),
          _DataCell('${row.lost}', width: 28, color: AppColors.error),
          if (showGoalDifference)
            _DataCell(_signed(row.goalDifference),
                width: 32, color: AppColors.whiteSubtle),
          _DataCell(
            '${row.points}',
            width: 36,
            color: AppColors.primaryLight,
            bold: true,
            fontSize: 15,
          ),
        ],
      ),
    );
  }

  static String _signed(int value) => value > 0 ? '+$value' : '$value';
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final double width;
  final bool highlight;

  const _HeaderCell(this.text, {required this.width, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: highlight ? AppColors.primaryLight : AppColors.whiteSubtle,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  final double width;
  final Color color;
  final bool bold;
  final double fontSize;

  const _DataCell(
    this.text, {
    required this.width,
    required this.color,
    this.bold = false,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _PositionBadge extends StatelessWidget {
  final int position;

  const _PositionBadge({required this.position});

  @override
  Widget build(BuildContext context) {
    final Color? badgeColor = switch (position) {
      1 => AppColors.podiumGold,
      2 => AppColors.podiumSilver,
      3 => AppColors.podiumBronze,
      _ => null,
    };

    if (badgeColor != null) {
      return SizedBox(
        width: 28,
        child: Center(
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
            child: Center(
              child: Text(
                '$position',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 28,
      child: Text(
        '$position',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 13),
      ),
    );
  }
}
