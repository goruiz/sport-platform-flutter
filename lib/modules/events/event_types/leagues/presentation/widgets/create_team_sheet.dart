import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final _picker = ImagePicker();
  File? _pickedImage;
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

  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.sheetBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.white,
              ),
              title: Text(
                'leagues.pick_image_gallery'.tr(),
                style: const TextStyle(color: AppColors.white),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.white,
              ),
              title: Text(
                'leagues.pick_image_camera'.tr(),
                style: const TextStyle(color: AppColors.white),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      String? logoUrl;

      // TODO: Uncomment when cloud storage (TeamLogoStorageService) is configured.
      // if (_pickedImage != null) {
      //   final storageService = getIt<TeamLogoStorageService>();
      //   logoUrl = await storageService.uploadLogo(_pickedImage!);
      // }

      final team = await _teamsService.create(
        _nameCtrl.text.trim(),
        logoUrl: logoUrl,
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
              Text(
                'leagues.team_logo'.tr(),
                style: const TextStyle(
                  color: AppColors.whiteSubtle,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _saving ? null : _showImageSourceSheet,
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: _pickedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            _pickedImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_photo_alternate_outlined,
                              color: AppColors.whiteSubtle,
                              size: 32,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'leagues.team_logo'.tr(),
                              style: const TextStyle(
                                color: AppColors.whiteSubtle,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                ),
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
