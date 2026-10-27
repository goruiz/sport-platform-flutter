import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/events/shared/data/models/championship_model.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/match_stage.dart';
import 'package:sport_platform/modules/events/shared/presentation/utils/championship_labels.dart';

/// Una ronda de la llave (Final, Semifinales…) con sus cruces.
class ChampionshipRoundCard extends StatelessWidget {
  final ChampionshipRoundModel round;
  final ChampionshipModel championship;

  const ChampionshipRoundCard({
    super.key,
    required this.round,
    required this.championship,
  });

  @override
  Widget build(BuildContext context) {
    final title = describeRound(round);
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
        ...round.ties.map((tie) => _TieTile(tie: tie, championship: championship)),
      ],
    );
  }
}

class _TieTile extends StatelessWidget {
  final TieModel tie;
  final ChampionshipModel championship;

  const _TieTile({required this.tie, required this.championship});

  // Las etapas que merecen una etiqueta propia sobre el cruce; la eliminatoria normal no la necesita.
  static const _labelledStages = {
    MatchStage.thirdPlace,
    MatchStage.grandFinal,
    MatchStage.winners,
    MatchStage.losers,
  };

  @override
  Widget build(BuildContext context) {
    final stage = tie.stage;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stage != null && _labelledStages.contains(stage)) ...[
            Text(
              stage.translationKey.tr(),
              style: const TextStyle(
                color: AppColors.primaryLight,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
          ],
          _TeamLine(
            name: _nameOf(tie.teamAId),
            goals: tie.hasResult ? tie.teamAGoals : null,
            isWinner: tie.winnerTeamId != null && tie.winnerTeamId == tie.teamAId,
          ),
          const SizedBox(height: 6),
          if (tie.bye)
            Text(
              'championship.bye'.tr(),
              style: const TextStyle(
                color: AppColors.whiteSubtle,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            _TeamLine(
              name: _nameOf(tie.teamBId),
              goals: tie.hasResult ? tie.teamBGoals : null,
              isWinner: tie.winnerTeamId != null && tie.winnerTeamId == tie.teamBId,
            ),
          if (tie.needsTiebreak) ...[
            const SizedBox(height: 8),
            Text(
              'championship.needs_tiebreak'.tr(),
              style: const TextStyle(color: AppColors.warning, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  String _nameOf(String? teamId) =>
      championship.teamName(teamId) ?? 'championship.tbd'.tr();
}

class _TeamLine extends StatelessWidget {
  final String name;
  final int? goals;
  final bool isWinner;

  const _TeamLine({required this.name, required this.goals, required this.isWinner});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isWinner ? AppColors.primaryLight : AppColors.white,
              fontSize: 14,
              fontWeight: isWinner ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
        if (isWinner)
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.check_circle, size: 16, color: AppColors.primaryLight),
          ),
        if (goals != null)
          Text(
            '$goals',
            style: TextStyle(
              color: isWinner ? AppColors.primaryLight : AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }
}
