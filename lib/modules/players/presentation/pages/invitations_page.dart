import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/players/data/models/team_invitation_model.dart';
import 'package:sport_platform/modules/players/presentation/providers/invitations_notifier.dart';
import 'package:sport_platform/modules/players/presentation/widgets/invitation_tile.dart';
import 'package:sport_platform/shared/mixins/snack_mixin.dart';
import 'package:sport_platform/shared/widgets/empty_state.dart';
import 'package:sport_platform/shared/widgets/error_retry.dart';

/// La bandeja de invitaciones a equipos: se aceptan o se rechazan desde aquí.
class InvitationsPage extends StatefulWidget {
  const InvitationsPage({super.key});

  @override
  State<InvitationsPage> createState() => _InvitationsPageState();
}

class _InvitationsPageState extends State<InvitationsPage> with SnackMixin {
  final InvitationsNotifier _notifier = getIt<InvitationsNotifier>();
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _notifier.load();
  }

  Future<void> _answer(
    TeamInvitationModel invitation, {
    required bool accept,
  }) async {
    setState(() => _busyIds.add(invitation.id));
    final failureKey = accept
        ? await _notifier.accept(invitation.id)
        : await _notifier.decline(invitation.id);
    if (!mounted) return;
    setState(() => _busyIds.remove(invitation.id));
    if (failureKey != null) {
      showSnack(failureKey.tr(), isError: true);
      return;
    }
    showSnack(accept
        ? 'invitations.accepted'.tr(args: [invitation.teamName ?? ''])
        : 'invitations.declined'.tr());
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Scaffold(
      backgroundColor: AppColors.backgroundEnd,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: Text('invitations.title'.tr(),
            style: const TextStyle(color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: ListenableBuilder(listenable: _notifier, builder: (_, _) => _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_notifier.loading && !_notifier.loadedOnce) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryLight),
      );
    }
    final error = _notifier.error;
    if (error != null && _notifier.invitations.isEmpty) {
      return ErrorRetry(message: error.tr(), onRetry: _notifier.load);
    }
    return RefreshIndicator(
      onRefresh: _notifier.load,
      color: AppColors.primaryLight,
      child: _notifier.invitations.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.65,
                  child: EmptyState(
                    icon: Icons.mark_email_read_outlined,
                    title: 'invitations.empty_title'.tr(),
                    subtitle: 'invitations.empty_subtitle'.tr(),
                  ),
                ),
              ],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: _notifier.invitations
                  .map((invitation) => InvitationTile(
                        invitation: invitation,
                        busy: _busyIds.contains(invitation.id),
                        onAccept: () => _answer(invitation, accept: true),
                        onDecline: () => _answer(invitation, accept: false),
                      ))
                  .toList(),
            ),
    );
  }
}
