import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/core/utils/date_formatters.dart';
import 'package:sport_platform/modules/players/data/models/team_invitation_model.dart';
import 'package:sport_platform/shared/widgets/app_card.dart';
import 'package:sport_platform/shared/widgets/initials_avatar.dart';

/// Una invitación a un equipo con sus dos respuestas: aceptar o rechazar.
class InvitationTile extends StatelessWidget {
  final TeamInvitationModel invitation;

  /// Mientras se responde, los botones quedan deshabilitados para no mandar la respuesta dos veces.
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const InvitationTile({
    super.key,
    required this.invitation,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final expiresAt = invitation.expiresAt;
    final teamName = invitation.teamName ?? 'invitations.unknown_team'.tr();
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialsAvatar(name: teamName, size: 46),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(teamName, style: AppTextStyles.cardTitle.copyWith(fontSize: 16)),
                    const SizedBox(height: 2),
                    Text('invitations.invited_you'.tr(), style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          if (expiresAt != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(Icons.schedule, size: 15, color: AppColors.whiteSubtle),
                const SizedBox(width: 6),
                Text(
                  'invitations.expires'.tr(args: [DateFormatters.date(expiresAt)]),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onDecline,
                  child: Text('invitations.decline'.tr()),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton(
                  onPressed: busy ? null : onAccept,
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                        )
                      : Text('invitations.accept'.tr()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
