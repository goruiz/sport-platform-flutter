import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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
                child: Text('match_detail.attendance.title'.tr(), style: AppTextStyles.cardTitle),
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
                label: 'match_detail.attendance.confirm'.tr(),
                icon: Icons.check_circle_outline,
                isSelected: mine == AttendanceStatus.confirmed,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _answerButton(
                status: AttendanceStatus.declined,
                label: 'match_detail.attendance.decline'.tr(),
                icon: Icons.cancel_outlined,
                isSelected: mine == AttendanceStatus.declined,
              ),
            ),
          ],
        ),
        if (mine != null)
          TextButton(
            onPressed: isSaving ? null : onClearAnswer,
            child: Text('match_detail.attendance.clear'.tr()),
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
      AttendanceStatus.confirmed => 'match_detail.attendance.answered_confirmed'.tr(),
      AttendanceStatus.declined => 'match_detail.attendance.answered_declined'.tr(),
      null => 'match_detail.attendance.closed'.tr(),
    };
    return Text(text, style: AppTextStyles.bodyMuted);
  }

  Widget _buildTeamAnswers(TeamAttendance team) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'match_detail.attendance.summary'.tr(
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            attendee.playerName ?? 'match_detail.unknown_player'.tr(),
            style: AppTextStyles.caption.copyWith(color: AppColors.white),
          ),
        ],
      ),
    );
  }
}
