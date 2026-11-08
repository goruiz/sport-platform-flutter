import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/modules/reports/domain/team_report.dart';
import 'package:sport_platform/shared/enums/summary_status.dart';
import 'package:sport_platform/shared/widgets/app_card.dart';

/// La participación y la disciplina del equipo: en cuántos eventos juega y las tarjetas y faltas de sus jugadores.
/// Los eventos ya se saben con los partidos; lo demás llega con otra lectura y mientras tanto (o si falla) se ve «—».
class TeamStatsCard extends StatelessWidget {
  /// En cuántos eventos juega; null cuando la tarjeta es de un solo evento y ese dato no tiene sentido.
  final int? eventsPlayed;
  final SummaryStatus disciplineStatus;
  final TeamDiscipline discipline;
  final VoidCallback? onRetry;

  const TeamStatsCard({
    super.key,
    this.eventsPlayed,
    required this.disciplineStatus,
    required this.discipline,
    this.onRetry,
  });

  /// Lo que se muestra en un contador de disciplina: su valor, o «—» si aún no se tiene.
  String _disciplineValue(int value) =>
      disciplineStatus == SummaryStatus.ready ? '$value' : '—';

  @override
  Widget build(BuildContext context) {
    context.locale;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (eventsPlayed != null)
                _Counter(
                  label: 'reports.events_played'.tr(),
                  value: '$eventsPlayed',
                ),
              _Counter(
                label: 'reports.yellow_cards'.tr(),
                value: _disciplineValue(discipline.yellowCards),
                color: AppColors.cardYellow,
              ),
              _Counter(
                label: 'reports.red_cards'.tr(),
                value: _disciplineValue(discipline.redCards),
                color: AppColors.cardRed,
              ),
              _Counter(
                label: 'reports.fouls'.tr(),
                value: _disciplineValue(discipline.fouls),
              ),
            ],
          ),
          if (disciplineStatus == SummaryStatus.failed) ...[
            const SizedBox(height: AppSpacing.md),
            _buildRetryRow(),
          ],
        ],
      ),
    );
  }

  Widget _buildRetryRow() => Row(
    children: [
      Expanded(
        child: Text('reports.team_stats_error'.tr(), style: AppTextStyles.caption),
      ),
      if (onRetry != null)
        TextButton(onPressed: onRetry, child: Text('common.retry'.tr())),
    ],
  );
}

class _Counter extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Counter({
    required this.label,
    required this.value,
    this.color = AppColors.white,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 2),
      Text(label, style: AppTextStyles.caption),
    ],
  );
}
