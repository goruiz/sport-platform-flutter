import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/shared/widgets/initials_avatar.dart';

/// La foto de perfil del encabezado, con su botón de cámara para cambiarla. Sin foto muestra las iniciales; mientras
/// se sube o se quita, un indicador de progreso encima. Solo dibuja y avisa: quien la usa decide qué pasa al tocarla.
class ProfileAvatar extends StatelessWidget {
  static const double _size = 88;
  static const double _cameraButtonSize = 32;

  final String name;
  final String? photoUrl;
  final bool isBusy;

  /// Se llama al tocar la foto o su botón de cámara; null la deja sin acción.
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.isBusy = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Semantics(
      button: onTap != null,
      label: 'mobile.profile.photo.change'.tr(),
      child: GestureDetector(
        onTap: isBusy ? null : onTap,
        child: SizedBox(
          width: _size + _cameraButtonSize / 2,
          height: _size + _cameraButtonSize / 2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 0,
                top: 0,
                child: InitialsAvatar(name: name, logoUrl: photoUrl, size: _size),
              ),
              if (isBusy)
                const Positioned(
                  left: 0,
                  top: 0,
                  width: _size,
                  height: _size,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Color(0x88000000), shape: BoxShape.circle),
                    child: Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.white),
                      ),
                    ),
                  ),
                ),
              if (onTap != null)
                const Positioned(right: 0, bottom: 0, child: _CameraBadge()),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraBadge extends StatelessWidget {
  const _CameraBadge();

  @override
  Widget build(BuildContext context) => Container(
        width: ProfileAvatar._cameraButtonSize,
        height: ProfileAvatar._cameraButtonSize,
        decoration: BoxDecoration(
          color: AppColors.action,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.backgroundEnd, width: 2),
        ),
        child: const Icon(Icons.photo_camera, size: 16, color: AppColors.white),
      );
}
