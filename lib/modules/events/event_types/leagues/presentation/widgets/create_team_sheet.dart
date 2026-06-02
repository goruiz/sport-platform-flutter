import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_input_decoration.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/teams_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/team_model.dart';
import 'package:sport_platform/shared/widgets/sheet_handle.dart';

class CreateTeamSheet extends StatefulWidget {
  final String initialName;
  final Future<void> Function(TeamModel) onCreated;

  const CreateTeamSheet({
    super.key,
    this.initialName = '',
    required this.onCreated,
  });

  static Future<void> show({
    required BuildContext context,
    String initialName = '',
    required Future<void> Function(TeamModel) onCreated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateTeamSheet(
        initialName: initialName,
        onCreated: onCreated,
      ),
    );
  }

  @override
  State<CreateTeamSheet> createState() => _CreateTeamSheetState();
}

class _CreateTeamSheetState extends State<CreateTeamSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  final _logoUrlCtrl = TextEditingController();
  bool _saving = false;
  late final TeamsService _teamsService;

  @override
  void initState() {
    super.initState();
    _teamsService = getIt<TeamsService>();
    _nameCtrl = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _logoUrlCtrl.dispose();
    super.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final logoUrl = _logoUrlCtrl.text.trim();
      final team = await _teamsService.create(
        _nameCtrl.text.trim(),
        logoUrl: logoUrl.isEmpty ? null : logoUrl,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      await widget.onCreated(team);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        _showSnack('leagues.error_create_team'.tr(), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.sheetBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              const SizedBox(height: 20),
              Text(
                'leagues.create_team'.tr(),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameCtrl,
                autofocus: true,
                style: const TextStyle(color: AppColors.white),
                decoration: AppInputDecoration.standard(
                  'leagues.team_name'.tr(),
                ).copyWith(
                  prefixIcon: const Icon(
                    Icons.groups_outlined,
                    color: AppColors.whiteSubtle,
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'leagues.team_name_required'.tr()
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _logoUrlCtrl,
                style: const TextStyle(color: AppColors.white),
                decoration: AppInputDecoration.standard(
                  'leagues.team_logo_url'.tr(),
                ).copyWith(
                  prefixIcon: const Icon(
                    Icons.image_outlined,
                    color: AppColors.whiteSubtle,
                  ),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _saving ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.inputBorder),
                        foregroundColor: AppColors.whiteSubtle,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text('leagues.cancel'.tr()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : Text(
                              'common.create'.tr(),
                              style: const TextStyle(color: AppColors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
