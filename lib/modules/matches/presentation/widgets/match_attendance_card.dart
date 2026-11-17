import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/locale_keys.g.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/modules/matches/data/models/match_attendance_model.dart';
import 'package:sport_platform/modules/matches/domain/match_attendance_rules.dart';
import 'package:sport_platform/shared/widgets/app_card.dart';

/// «¿Asistirás al partido?»: la respuesta del propio jugador y quiénes de su equipo van. Solo dibuja y avisa: quien la
/// usa lee y guarda la asistencia.
class MatchAttendanceCard extends StatelessWidget {
  final MatchAttendanceModel attendance;

  /// El equipo del jugador: de él se muestra quién va. Los del rival no se listan.
  final String? myTeamId;

  /// Todavía se puede responder; si no, solo se ve lo que ya se respondió.
  final bool canAnswer;
  final bool isSaving;
  final ValueChanged<AttendanceStatus> onAnswer;
  final VoidCallback onClearAnswer;

  const MatchAttendanceCard({
    super.key,
    required this.attendance,
    required this.myTeamId,
    required this.canAnswer,
    required this.isSaving,
    required this.onAnswer,
    required this.onClearAnswer,
  });

  @override
  Widget build(BuildContext context) {
    context.locale;
    final team = splitTeamAttendance(attendance.attendees, myTeamId);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.how_to_reg_outlined, color: AppColors.primaryLight, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(LocaleKeys.match_detail_attendance_title.tr(), style: AppTextStyles.cardTitle),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (canAnswer) _buildAnswerButtons() else _buildClosedNote(),
          if (team.hasAnswers) ...[
            const SizedBox(height: AppSpacing.lg),
            _buildTeamAnswers(team),
          ],
        ],
      ),
    );
  }

  Widget _buildAnswerButtons() {
    final mine = attendance.myStatus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _answerButton(
                status: AttendanceStatus.confirmed,
                label: LocaleKeys.match_detail_attendance_confirm.tr(),
                icon: Icons.check_circle_outline,
                isSelected: mine == AttendanceStatus.confirmed,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _answerButton(
                status: AttendanceStatus.declined,
                label: LocaleKeys.match_detail_attendance_decline.tr(),
                icon: Icons.cancel_outlined,
                isSelected: mine == AttendanceStatus.declined,
              ),
            ),
          ],
        ),
        if (mine != null)
          TextButton(
            onPressed: isSaving ? null : onClearAnswer,
            child: Text(LocaleKeys.match_detail_attendance_clear.tr()),
          ),
      ],
    );
  }

  Widget _answerButton({
    required AttendanceStatus status,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    final onPressed = isSaving ? null : () => onAnswer(status);
    final child = Text(label, textAlign: TextAlign.center);
    return isSelected
        ? FilledButton.icon(onPressed: onPressed, icon: Icon(icon, size: 18), label: child)
        : OutlinedButton.icon(onPressed: onPressed, icon: Icon(icon, size: 18), label: child);
  }

  /// Cuando ya no se puede responder: lo que dijo el jugador, o por qué no hay botones.
  Widget _buildClosedNote() {
    final text = switch (attendance.myStatus) {
      AttendanceStatus.confirmed => LocaleKeys.match_detail_attendance_answered_confirmed.tr(),
      AttendanceStatus.declined => LocaleKeys.match_detail_attendance_answered_declined.tr(),
      null => LocaleKeys.match_detail_attendance_closed.tr(),
    };
    return Text(text, style: AppTextStyles.bodyMuted);
  }

  Widget _buildTeamAnswers(TeamAttendance team) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.match_detail_attendance_summary.tr(
            namedArgs: {'confirmed': '${team.confirmed.length}', 'declined': '${team.declined.length}'},
          ),
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final attendee in team.confirmed)
              _AttendeeChip(attendee: attendee, color: AppColors.success, icon: Icons.check),
            for (final attendee in team.declined)
              _AttendeeChip(attendee: attendee, color: AppColors.whiteSubtle, icon: Icons.close),
          ],
        ),
      ],
    );
  }
}

class _AttendeeChip extends StatelessWidget {
  final MatchAttendee attendee;
  final Color color;
  final IconData icon;

  const _AttendeeChip({required this.attendee, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.tight),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            attendee.playerName ?? LocaleKeys.match_detail_unknown_player.tr(),
            style: AppTextStyles.caption.copyWith(color: AppColors.white),
          ),
        ],
      ),
    );
  }
}
