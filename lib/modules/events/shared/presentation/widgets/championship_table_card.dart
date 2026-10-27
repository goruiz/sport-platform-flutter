import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/events/shared/data/models/championship_model.dart';
import 'package:sport_platform/modules/events/shared/presentation/utils/championship_labels.dart';
import 'package:sport_platform/shared/widgets/standings_table.dart';

/// La tabla de puntos de una etapa (la liga, el suizo o un grupo), con su título.
class ChampionshipTableCard extends StatelessWidget {
  final ChampionshipTableModel table;

  /// Cuántas de sus primeras filas pasan a la eliminatoria; 0 si ninguna.
  final int advancingRows;

  const ChampionshipTableCard({
    super.key,
    required this.table,
    required this.advancingRows,
  });

  @override
  Widget build(BuildContext context) {
    final title = describeTable(table);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text(
            title.key.tr(args: title.args),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        StandingsTable(
          rows: table.entries.map(_toRow).toList(),
          advancingRows: advancingRows,
          showGoalDifference: true,
        ),
      ],
    );
  }

  static StandingsTableRow _toRow(ChampionshipTableEntryModel entry) =>
      StandingsTableRow(
        position: entry.position,
        teamName: entry.teamName,
        played: entry.played,
        won: entry.won,
        drawn: entry.drawn,
        lost: entry.lost,
        goalDifference: entry.goalDifference,
        points: entry.points,
      );
}
