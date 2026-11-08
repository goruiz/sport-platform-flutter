import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/event_rule_kind.dart';
import 'package:sport_platform/modules/events/shared/presentation/utils/event_rules_labels.dart';
import 'package:sport_platform/shared/widgets/app_card.dart';
import 'package:sport_platform/shared/widgets/info_row.dart';

/// Las reglas del torneo que definió el organizador: sistema de juego, puntos, desempates, grupos, eliminatoria y
/// límites de jugadores por equipo. No se dibuja nada si el evento no tiene reglas que contar.
class EventRulesCard extends StatelessWidget {
  final EventModel event;

  const EventRulesCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    context.locale;
    final lines = describeEventRules(
      event.formatRules,
      minPlayersPerTeam: event.minPlayersPerTeam,
      maxPlayersPerTeam: event.maxPlayersPerTeam,
    );
    if (lines.isEmpty) return const SizedBox.shrink();
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('event_rules.title'.tr(), style: AppTextStyles.sectionTitle),
          for (final line in lines) ...[
            const SizedBox(height: AppSpacing.md),
            InfoRow(icon: _iconOf(line.kind), title: line.kind.translationKey.tr(), label: _valueOf(line)),
          ],
        ],
      ),
    );
  }

  /// Los valores uno por línea; los que van en orden de prioridad (desempates) se numeran.
  String _valueOf(EventRuleLine line) {
    final values = [for (final value in line.values) value.key.tr(args: value.args)];
    if (!line.kind.isOrdered) return values.join('\n');
    return [for (var i = 0; i < values.length; i++) '${i + 1}. ${values[i]}'].join('\n');
  }

  IconData _iconOf(EventRuleKind kind) => switch (kind) {
        EventRuleKind.structure => Icons.account_tree_outlined,
        EventRuleKind.roundTrip || EventRuleKind.knockoutRoundTrip => Icons.swap_horiz,
        EventRuleKind.points => Icons.scoreboard_outlined,
        EventRuleKind.tiebreakers => Icons.balance,
        EventRuleKind.swissRounds => Icons.repeat,
        EventRuleKind.groupCount || EventRuleKind.teamsAdvancingPerGroup => Icons.grid_view,
        EventRuleKind.playoffTeams => Icons.emoji_events_outlined,
        EventRuleKind.thirdPlaceMatch || EventRuleKind.grandFinalReset => Icons.military_tech_outlined,
        EventRuleKind.playersPerTeam => Icons.groups_outlined,
      };
}
