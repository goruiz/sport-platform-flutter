import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/players/presentation/pages/invitations_page.dart';
import 'package:sport_platform/modules/players/presentation/providers/invitations_notifier.dart';

/// La campana de la barra superior: abre la bandeja de invitaciones y avisa cuántas hay pendientes.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = getIt<InvitationsNotifier>();
    return ListenableBuilder(
      listenable: notifier,
      builder: (context, _) => IconButton(
        tooltip: 'invitations.title'.tr(),
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const InvitationsPage())),
        icon: Badge(
          isLabelVisible: notifier.pendingCount > 0,
          label: Text('${notifier.pendingCount}'),
          child: const Icon(
            Icons.notifications_outlined,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}
