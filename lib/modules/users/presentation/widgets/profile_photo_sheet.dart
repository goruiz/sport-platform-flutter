import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/shared/widgets/sheet_handle.dart';

/// Lo que la persona decide hacer con su foto de perfil.
enum ProfilePhotoAction { takePhoto, chooseFromGallery, remove }

/// Abre una hoja inferior con lo que se puede hacer con la foto de perfil y devuelve lo elegido; null si la cierra
/// sin elegir. «Quitar foto» solo se ofrece si [hasPhoto].
Future<ProfilePhotoAction?> showProfilePhotoSheet(BuildContext context, {required bool hasPhoto}) {
  return showModalBottomSheet<ProfilePhotoAction>(
    context: context,
    builder: (_) => _ProfilePhotoSheet(hasPhoto: hasPhoto),
  );
}

class _ProfilePhotoSheet extends StatelessWidget {
  final bool hasPhoto;

  const _ProfilePhotoSheet({required this.hasPhoto});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, AppSpacing.md, 0, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.sm),
              child: Text('mobile.profile.photo.change'.tr(), style: AppTextStyles.sectionTitle),
            ),
            _option(context, ProfilePhotoAction.takePhoto, Icons.photo_camera_outlined, 'mobile.profile.photo.take'.tr()),
            _option(
              context,
              ProfilePhotoAction.chooseFromGallery,
              Icons.photo_library_outlined,
              'mobile.profile.photo.choose'.tr(),
            ),
            if (hasPhoto)
              _option(
                context,
                ProfilePhotoAction.remove,
                Icons.delete_outline,
                'mobile.profile.photo.remove'.tr(),
                color: AppColors.error,
              ),
          ],
        ),
      ),
    );
  }

  Widget _option(
    BuildContext context,
    ProfilePhotoAction action,
    IconData icon,
    String label, {
    Color color = AppColors.white,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      leading: Icon(icon, color: color == AppColors.white ? AppColors.primaryLight : color),
      title: Text(label, style: AppTextStyles.body.copyWith(fontSize: 16, color: color)),
      onTap: () => Navigator.of(context).pop(action),
    );
  }
}
