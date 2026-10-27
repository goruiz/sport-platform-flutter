import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/strings_constants/home_strings_constants.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/home/presentation/widgets/empty_card.dart';
import 'package:sport_platform/modules/players/presentation/pages/invitations_page.dart';
import 'package:sport_platform/modules/players/presentation/providers/invitations_notifier.dart';

/// Las invitaciones a equipos que esperan respuesta: «sin invitaciones» o cuántas hay, con un toque
/// para abrir la bandeja.
class InvitationsCard extends StatelessWidget {
  const InvitationsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = getIt<InvitationsNotifier>();
    return ListenableBuilder(
      listenable: notifier,
      builder: (context, _) {
        if (notifier.pendingCount == 0) {
          return EmptyCard(
            icon: Icons.check_circle_outline,
            message: HomeStringsConstants.noInvitations.tr(),
          );
        }
        final teamNames = notifier.invitations
            .map((invitation) => invitation.teamName)
            .whereType<String>()
            .join(', ');
        return Material(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const InvitationsPage()),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mark_email_unread_outlined,
                      color: AppColors.primaryLight, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'invitations.pending_count'
                              .tr(namedArgs: {'count': '${notifier.pendingCount}'}),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (teamNames.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            teamNames,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.whiteSubtle, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.whiteSubtle),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
