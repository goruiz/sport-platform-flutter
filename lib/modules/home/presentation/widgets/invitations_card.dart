import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/modules/players/presentation/pages/invitations_page.dart';
import 'package:sport_platform/modules/players/presentation/providers/invitations_notifier.dart';
import 'package:sport_platform/shared/widgets/app_card.dart';

/// Las invitaciones a equipos que esperan respuesta: cuántas hay, con un toque para abrir la bandeja.
/// No se dibuja nada si no hay ninguna: sin invitaciones no hay nada que decidir.
class InvitationsCard extends StatelessWidget {
  const InvitationsCard({super.key});

  /// «Tienes 1 invitación pendiente» / «Tienes 3 invitaciones pendientes»: el singular tiene su propio texto.
  static String _title(int count) => count == 1
      ? 'invitations.pending_count_one'.tr()
      : 'invitations.pending_count'.tr(namedArgs: {'count': '$count'});

  @override
  Widget build(BuildContext context) {
    final notifier = getIt<InvitationsNotifier>();
    return ListenableBuilder(
      listenable: notifier,
      builder: (context, _) {
        if (notifier.pendingCount == 0) return const SizedBox.shrink();
        final teamNames = notifier.invitations
            .map((invitation) => invitation.teamName)
            .whereType<String>()
            .join(', ');
        return AppCard(
          accent: AppColors.warning,
          margin: const EdgeInsets.only(bottom: AppSpacing.xl),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const InvitationsPage()),
          ),
          child: Row(
            children: [
              const Icon(Icons.mark_email_unread_outlined, color: AppColors.warningLight, size: 28),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_title(notifier.pendingCount), style: AppTextStyles.cardTitle),
                    if (teamNames.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        teamNames,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.whiteSubtle),
            ],
          ),
        );
      },
    );
  }
}
