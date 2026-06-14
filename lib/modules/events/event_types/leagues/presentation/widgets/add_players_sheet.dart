import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_input_decoration.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_invitation_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/team_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/providers/add_players_notifier.dart';
import 'package:sport_platform/shared/widgets/sheet_handle.dart';

class AddPlayersSheet extends StatefulWidget {
  final TeamModel team;
  final bool isEditMode;
  final PlayersService playersService;

  const AddPlayersSheet({
    super.key,
    required this.team,
    required this.playersService,
    this.isEditMode = false,
  });

  static Future<void> show({
    required BuildContext context,
    required TeamModel team,
    bool isEditMode = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: isEditMode,
      enableDrag: isEditMode,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPlayersSheet(
        team: team,
        isEditMode: isEditMode,
        playersService: getIt<PlayersService>(),
      ),
    );
  }

  @override
  State<AddPlayersSheet> createState() => _AddPlayersSheetState();
}

class _AddPlayersSheetState extends State<AddPlayersSheet> {
  final _searchFormKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  late final AddPlayersNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = AddPlayersNotifier(
      service: widget.playersService,
      teamId: widget.team.id,
      isEditMode: widget.isEditMode,
    );
    if (widget.isEditMode) _notifier.load();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _notifier.dispose();
    super.dispose();
  }

  // ── Actions delegated to notifier ────────────────────────────────────────────

  Future<void> _searchUser() async {
    if (!_searchFormKey.currentState!.validate()) return;
    await _notifier.searchUser(_emailCtrl.text.trim());
  }

  Future<void> _inviteExistingUser() async {
    final email = _emailCtrl.text.trim();
    final success = await _notifier.inviteExistingUser(email);
    if (success && mounted) {
      _showSnack('players.invitation_sent'.tr(args: [email]));
      _clearSearch();
    }
  }

  Future<void> _sendRegistrationLink() async {
    final email = _emailCtrl.text.trim();
    final success = await _notifier.sendRegistrationLink(email);
    if (success && mounted) {
      _showSnack('players.registration_link_sent'.tr(args: [email]));
      _clearSearch();
    }
  }

  Future<void> _removePlayerFromTeam(PlayerModel player) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.sheetBackground,
        title: Text(
          'players.confirm_remove_title'.tr(),
          style: const TextStyle(color: AppColors.white),
        ),
        content: Text(
          'players.confirm_remove_body'.tr(args: [player.fullName]),
          style: const TextStyle(color: AppColors.whiteSubtle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('leagues.cancel'.tr(),
                style: const TextStyle(color: AppColors.whiteSubtle)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('leagues.delete'.tr(),
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final success = await _notifier.removePlayer(player.id);
    if (!success && mounted) _showSnack('players.error_remove'.tr());
  }

  // ── UI helpers ────────────────────────────────────────────────────────────────

  void _clearSearch() {
    _emailCtrl.clear();
    _searchFormKey.currentState?.reset();
    _notifier.clearSearch();
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _finish() {
    if (!widget.isEditMode &&
        _notifier.addedPlayers.length < AddPlayersNotifier.minPlayers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('players.min_required'
              .tr(args: [AddPlayersNotifier.minPlayers.toString()])),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  void _skip() => Navigator.of(context).pop();

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return ListenableBuilder(
      listenable: _notifier,
      builder: (context, _) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.92,
          ),
          decoration: const BoxDecoration(
            color: AppColors.sheetBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              const SizedBox(height: 16),
              _buildHeader(),
              const SizedBox(height: 16),
              Flexible(child: _buildPlayerList()),
              if (!_notifier.atMax) ...[
                const SizedBox(height: 16),
                _buildDivider(),
                const SizedBox(height: 16),
                _buildSearchForm(),
                if (_notifier.searchPerformed) ...[
                  const SizedBox(height: 12),
                  _buildSearchResult(),
                ],
              ],
              if (_notifier.atMax)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'players.max_reached'.tr(
                        args: [AddPlayersNotifier.maxPlayers.toString()]),
                    style: const TextStyle(
                        color: AppColors.warning, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 20),
              _buildActions(),
            ],
          ),
        );
      },
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final titleKey = widget.isEditMode
        ? 'players.manage_players_title'
        : 'players.add_players_title';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titleKey.tr(args: [widget.team.name]),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'players.count_hint'.tr(args: [
                  _notifier.totalCount.toString(),
                  AddPlayersNotifier.maxPlayers.toString(),
                ]),
                style: TextStyle(
                  color: (!widget.isEditMode &&
                          _notifier.totalCount <
                              AddPlayersNotifier.minPlayers)
                      ? AppColors.warning
                      : AppColors.primaryLight,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        _buildCountBadge(),
      ],
    );
  }

  Widget _buildCountBadge() {
    final insufficient = !widget.isEditMode &&
        _notifier.totalCount < AddPlayersNotifier.minPlayers;
    final color = insufficient ? AppColors.warning : AppColors.primaryLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '${_notifier.totalCount} / ${AddPlayersNotifier.maxPlayers}',
        style: TextStyle(
            color: color, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  // ── Player list ──────────────────────────────────────────────────────────────

  Widget _buildPlayerList() {
    if (_notifier.loadingExisting) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(color: AppColors.primaryLight),
        ),
      );
    }

    if (_notifier.loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_notifier.loadError!.tr(),
                  style:
                      const TextStyle(color: AppColors.error, fontSize: 13)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _notifier.load,
                child: Text('common.retry'.tr(),
                    style:
                        const TextStyle(color: AppColors.primaryLight)),
              ),
            ],
          ),
        ),
      );
    }

    final hasAny = _notifier.existingPlayers.isNotEmpty ||
        _notifier.addedPlayers.isNotEmpty;

    if (!hasAny) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            widget.isEditMode
                ? 'players.no_players_yet'.tr()
                : 'players.empty_hint'
                    .tr(args: [AddPlayersNotifier.minPlayers.toString()]),
            style: const TextStyle(
                color: AppColors.whiteSubtle, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final allItems = <Widget>[];
    final existing = _notifier.existingPlayers;
    final added = _notifier.addedPlayers;

    for (var i = 0; i < existing.length; i++) {
      final p = existing[i];
      allItems.add(_ExistingPlayerTile(
        index: i + 1,
        player: p,
        onRemove: widget.isEditMode ? () => _removePlayerFromTeam(p) : null,
      ));
      if (i < existing.length - 1 || added.isNotEmpty) {
        allItems.add(const Divider(height: 1, color: AppColors.inputBorder));
      }
    }

    for (var i = 0; i < added.length; i++) {
      final p = added[i];
      allItems.add(_NewInvitationTile(
        index: existing.length + i + 1,
        invitation: p,
      ));
      if (i < added.length - 1) {
        allItems.add(const Divider(height: 1, color: AppColors.inputBorder));
      }
    }

    return ListView(shrinkWrap: true, children: allItems);
  }

  // ── Divider ──────────────────────────────────────────────────────────────────

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.inputBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'players.add_player'.tr(),
            style: const TextStyle(
                color: AppColors.whiteSubtle, fontSize: 12),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.inputBorder)),
      ],
    );
  }

  // ── Search form ──────────────────────────────────────────────────────────────

  Widget _buildSearchForm() {
    return Form(
      key: _searchFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _emailCtrl,
                  style: const TextStyle(color: AppColors.white),
                  keyboardType: TextInputType.emailAddress,
                  onFieldSubmitted: (_) =>
                      _notifier.searching ? null : _searchUser(),
                  decoration: AppInputDecoration.standard(
                    'players.search_placeholder'.tr(),
                  ).copyWith(
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.whiteSubtle,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'players.email_required'.tr();
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                        .hasMatch(v.trim())) {
                      return 'players.email_invalid'.tr();
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _notifier.searching ? null : _searchUser,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _notifier.searching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.white),
                        )
                      : Text(
                          'players.search_button'.tr(),
                          style:
                              const TextStyle(color: AppColors.white),
                        ),
                ),
              ),
            ],
          ),
          if (_notifier.searchError != null) ...[
            const SizedBox(height: 6),
            Text(
              _notifier.searchError!.tr(),
              style:
                  const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  // ── Search result ─────────────────────────────────────────────────────────────

  Widget _buildSearchResult() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _notifier.foundUser != null
          ? _buildFoundUser(_notifier.foundUser!)
          : _buildUserNotFound(),
    );
  }

  Widget _buildFoundUser(PlayerModel user) {
    return Container(
      key: const ValueKey('found'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primaryLight.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline,
                  color: AppColors.primaryLight, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName,
                        style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    Text(user.email,
                        style: const TextStyle(
                            color: AppColors.whiteSubtle, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.35)),
                ),
                child: Text(
                  'players.found_user'.tr(),
                  style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          if (_notifier.inviteError != null) ...[
            const SizedBox(height: 6),
            Text(_notifier.inviteError!.tr(),
                style:
                    const TextStyle(color: AppColors.error, fontSize: 12)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed:
                  _notifier.sendingInvitation ? null : _inviteExistingUser,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: _notifier.sendingInvitation
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.white))
                  : const Icon(Icons.mark_email_unread_outlined,
                      size: 18, color: AppColors.white),
              label: Text('players.invite_existing'.tr(),
                  style: const TextStyle(color: AppColors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserNotFound() {
    return Container(
      key: const ValueKey('not_found'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  color: AppColors.warning, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'players.user_not_found'.tr(),
                      style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'players.user_not_found_hint'.tr(),
                      style: const TextStyle(
                          color: AppColors.whiteSubtle, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_notifier.inviteError != null) ...[
            const SizedBox(height: 6),
            Text(_notifier.inviteError!.tr(),
                style:
                    const TextStyle(color: AppColors.error, fontSize: 12)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _notifier.sendingInvitation
                  ? null
                  : _sendRegistrationLink,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.warning,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: _notifier.sendingInvitation
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.white))
                  : const Icon(Icons.outgoing_mail,
                      size: 18, color: AppColors.white),
              label: Text('players.invite_new'.tr(),
                  style: const TextStyle(color: AppColors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom actions ────────────────────────────────────────────────────────────

  Widget _buildActions() {
    if (widget.isEditMode) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _skip,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: Text('players.close'.tr(),
              style: const TextStyle(color: AppColors.white)),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _skip,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.inputBorder),
              foregroundColor: AppColors.whiteSubtle,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('players.skip'.tr()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: _finish,
            style: FilledButton.styleFrom(
              backgroundColor: _notifier.canFinish
                  ? AppColors.primaryLight
                  : AppColors.primaryLight.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('players.done'.tr(),
                style: const TextStyle(color: AppColors.white)),
          ),
        ),
      ],
    );
  }
}

// ── Tile widgets ──────────────────────────────────────────────────────────────

class _ExistingPlayerTile extends StatelessWidget {
  final int index;
  final PlayerModel player;
  final VoidCallback? onRemove;

  const _ExistingPlayerTile({
    required this.index,
    required this.player,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: _IndexBadge(index: index, color: AppColors.primaryLight),
      title: Text(player.fullName,
          style: const TextStyle(color: AppColors.white, fontSize: 14)),
      subtitle: Text(player.email,
          style:
              const TextStyle(color: AppColors.whiteSubtle, fontSize: 12)),
      trailing: onRemove != null
          ? IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.person_remove_outlined,
                  color: AppColors.error, size: 18),
              tooltip: 'players.remove_from_team'.tr(),
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 32, minHeight: 32),
            )
          : _StatusBadge(
              label: 'players.status_active'.tr(),
              color: AppColors.success,
            ),
    );
  }
}

class _NewInvitationTile extends StatelessWidget {
  final int index;
  final PlayerInvitation invitation;

  const _NewInvitationTile(
      {required this.index, required this.invitation});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: _IndexBadge(index: index, color: AppColors.primaryLight),
      title: Text(invitation.displayName,
          style: const TextStyle(color: AppColors.white, fontSize: 14)),
      subtitle: invitation.isExisting
          ? null
          : Text(invitation.email,
              style: const TextStyle(
                  color: AppColors.whiteSubtle, fontSize: 12)),
      trailing: _StatusBadge(
        label: invitation.isExisting
            ? 'players.status_invited'.tr()
            : 'players.status_pending_registration'.tr(),
        color: invitation.isExisting
            ? AppColors.primaryLight
            : AppColors.warning,
      ),
    );
  }
}

class _IndexBadge extends StatelessWidget {
  final int index;
  final Color color;

  const _IndexBadge({required this.index, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$index',
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}
