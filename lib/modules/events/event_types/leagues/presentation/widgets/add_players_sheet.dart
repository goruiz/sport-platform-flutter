import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_input_decoration.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_invitation_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/team_model.dart';
import 'package:sport_platform/shared/widgets/sheet_handle.dart';

class AddPlayersSheet extends StatefulWidget {
  static const int minPlayers = 1;
  static const int maxPlayers = 30;

  final TeamModel team;

  const AddPlayersSheet({super.key, required this.team});

  static Future<void> show({
    required BuildContext context,
    required TeamModel team,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPlayersSheet(team: team),
    );
  }

  @override
  State<AddPlayersSheet> createState() => _AddPlayersSheetState();
}

class _AddPlayersSheetState extends State<AddPlayersSheet> {
  final _searchFormKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  bool _searching = false;
  bool _sendingInvitation = false;

  /// null  = no search done yet
  /// value = last search result (found user or null = not found)
  PlayerModel? _foundUser;
  bool _searchPerformed = false;
  String? _searchError;
  String? _inviteError;

  final List<PlayerInvitation> _addedPlayers = [];
  late final PlayersService _playersService;

  @override
  void initState() {
    super.initState();
    _playersService = getIt<PlayersService>();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  // ── Search ──────────────────────────────────────────────────────────────────

  Future<void> _searchUser() async {
    if (!_searchFormKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim();

    if (_addedPlayers.any(
      (p) => p.email.toLowerCase() == email.toLowerCase(),
    )) {
      setState(() => _searchError = 'players.already_added'.tr());
      return;
    }

    setState(() {
      _searching = true;
      _searchError = null;
      _inviteError = null;
      _searchPerformed = false;
      _foundUser = null;
    });

    try {
      final user = await _playersService.searchByEmail(email);
      if (!mounted) return;
      setState(() {
        _searching = false;
        _searchPerformed = true;
        _foundUser = user;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _searchError = 'players.error_search'.tr();
      });
    }
  }

  // ── Invite existing user ─────────────────────────────────────────────────────

  Future<void> _inviteExistingUser() async {
    setState(() {
      _sendingInvitation = true;
      _inviteError = null;
    });

    final email = _emailCtrl.text.trim();

    try {
      await _playersService.inviteExistingUser(
        email: email,
        teamId: widget.team.id,
      );
      if (!mounted) return;
      setState(() {
        _addedPlayers.add(
          PlayerInvitation(
            email: email,
            firstName: _foundUser?.firstName,
            lastName: _foundUser?.lastName,
            isExisting: true,
          ),
        );
        _sendingInvitation = false;
      });
      _showSuccessSnackbar(
        'players.invitation_sent'.tr(args: [email]),
      );
      _clearSearch();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sendingInvitation = false;
        _inviteError = 'players.error_invite'.tr();
      });
    }
  }

  // ── Send registration link ───────────────────────────────────────────────────

  Future<void> _sendRegistrationLink() async {
    setState(() {
      _sendingInvitation = true;
      _inviteError = null;
    });

    final email = _emailCtrl.text.trim();

    try {
      await _playersService.inviteNewUser(
        email: email,
        teamId: widget.team.id,
      );
      if (!mounted) return;
      setState(() {
        _addedPlayers.add(
          PlayerInvitation(
            email: email,
            firstName: null,
            lastName: null,
            isExisting: false,
          ),
        );
        _sendingInvitation = false;
      });
      _showSuccessSnackbar(
        'players.registration_link_sent'.tr(args: [email]),
      );
      _clearSearch();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sendingInvitation = false;
        _inviteError = 'players.error_invite'.tr();
      });
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  void _clearSearch() {
    _emailCtrl.clear();
    _searchFormKey.currentState?.reset();
    setState(() {
      _foundUser = null;
      _searchPerformed = false;
      _searchError = null;
      _inviteError = null;
    });
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _finish() {
    if (_addedPlayers.length < AddPlayersSheet.minPlayers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'players.min_required'
                .tr(args: [AddPlayersSheet.minPlayers.toString()]),
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  void _skip() => Navigator.of(context).pop();

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final count = _addedPlayers.length;
    final atMax = count >= AddPlayersSheet.maxPlayers;

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
          _buildHeader(count),
          const SizedBox(height: 16),
          Flexible(child: _buildPlayerList()),
          if (!atMax) ...[
            const SizedBox(height: 16),
            _buildDivider(),
            const SizedBox(height: 16),
            _buildSearchForm(),
            if (_searchPerformed) ...[
              const SizedBox(height: 12),
              _buildSearchResult(),
            ],
          ],
          if (atMax)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'players.max_reached'
                    .tr(args: [AddPlayersSheet.maxPlayers.toString()]),
                style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 20),
          _buildActions(),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader(int count) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'players.add_players_title'.tr(args: [widget.team.name]),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'players.count_hint'.tr(args: [
                  count.toString(),
                  AddPlayersSheet.maxPlayers.toString(),
                ]),
                style: TextStyle(
                  color: count < AddPlayersSheet.minPlayers
                      ? AppColors.warning
                      : AppColors.primaryLight,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        _buildCountBadge(count),
      ],
    );
  }

  Widget _buildCountBadge(int count) {
    final color = count < AddPlayersSheet.minPlayers
        ? AppColors.warning
        : AppColors.primaryLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$count / ${AddPlayersSheet.maxPlayers}',
        style:
            TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  // ── Player list ──────────────────────────────────────────────────────────────

  Widget _buildPlayerList() {
    if (_addedPlayers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'players.empty_hint'
                .tr(args: [AddPlayersSheet.minPlayers.toString()]),
            style:
                const TextStyle(color: AppColors.whiteSubtle, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      itemCount: _addedPlayers.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: AppColors.inputBorder),
      itemBuilder: (_, i) {
        final p = _addedPlayers[i];
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${i + 1}',
                style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          title: Text(
            p.displayName,
            style: const TextStyle(color: AppColors.white, fontSize: 14),
          ),
          subtitle: p.isExisting
              ? null
              : Text(
                  p.email,
                  style: const TextStyle(
                      color: AppColors.whiteSubtle, fontSize: 12),
                ),
          trailing: _buildStatusBadge(p.isExisting),
        );
      },
    );
  }

  Widget _buildStatusBadge(bool isExisting) {
    final label = isExisting
        ? 'players.status_invited'.tr()
        : 'players.status_pending_registration'.tr();
    final color =
        isExisting ? AppColors.primaryLight : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
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
            style:
                const TextStyle(color: AppColors.whiteSubtle, fontSize: 12),
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
                  onFieldSubmitted: (_) => _searching ? null : _searchUser(),
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
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
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
                  onPressed: _searching ? null : _searchUser,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _searching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Text(
                          'players.search_button'.tr(),
                          style: const TextStyle(color: AppColors.white),
                        ),
                ),
              ),
            ],
          ),
          if (_searchError != null) ...[
            const SizedBox(height: 6),
            Text(
              _searchError!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  // ── Search result ────────────────────────────────────────────────────────────

  Widget _buildSearchResult() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _foundUser != null
          ? _buildFoundUser(_foundUser!)
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
          color: AppColors.primaryLight.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                color: AppColors.primaryLight,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(
                        color: AppColors.whiteSubtle,
                        fontSize: 12,
                      ),
                    ),
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
                    color: AppColors.success.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  'players.found_user'.tr(),
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (_inviteError != null) ...[
            const SizedBox(height: 6),
            Text(
              _inviteError!,
              style:
                  const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _sendingInvitation ? null : _inviteExistingUser,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: _sendingInvitation
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(
                      Icons.mark_email_unread_outlined,
                      size: 18,
                      color: AppColors.white,
                    ),
              label: Text(
                'players.invite_existing'.tr(),
                style: const TextStyle(color: AppColors.white),
              ),
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
          color: AppColors.warning.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.warning,
                size: 18,
              ),
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'players.user_not_found_hint'.tr(),
                      style: const TextStyle(
                        color: AppColors.whiteSubtle,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_inviteError != null) ...[
            const SizedBox(height: 6),
            Text(
              _inviteError!,
              style:
                  const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _sendingInvitation ? null : _sendRegistrationLink,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.warning,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: _sendingInvitation
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(
                      Icons.outgoing_mail,
                      size: 18,
                      color: AppColors.white,
                    ),
              label: Text(
                'players.invite_new'.tr(),
                style: const TextStyle(color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom actions ───────────────────────────────────────────────────────────

  Widget _buildActions() {
    final canFinish = _addedPlayers.length >= AddPlayersSheet.minPlayers;
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
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('players.skip'.tr()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: _finish,
            style: FilledButton.styleFrom(
              backgroundColor: canFinish
                  ? AppColors.primaryLight
                  : AppColors.primaryLight.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'players.done'.tr(),
              style: const TextStyle(color: AppColors.white),
            ),
          ),
        ),
      ],
    );
  }
}
