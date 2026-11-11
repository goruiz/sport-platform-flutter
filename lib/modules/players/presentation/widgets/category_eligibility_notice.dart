import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/modules/players/domain/enums/category_eligibility_issue.dart';

/// El aviso de que el jugador sigue en un equipo pero la categoría no lo deja jugar (por su género o su edad, o porque aún
/// no completó su perfil). Es un aviso y no una alarma: no pasa nada con su plantilla ni con sus datos, solo que mientras
/// no cumpla no se le registran goles ni tarjetas.
///
/// Si lo que falta son datos del perfil ([CategoryEligibilityIssue.needsProfileData]) ofrece ir a completarlos, que es
/// lo único que el jugador puede hacer por sí mismo.
class CategoryEligibilityNotice extends StatelessWidget {
  /// Por qué no puede jugar; null si el backend dice un motivo que esta versión no conoce (se avisa sin detalle).
  final CategoryEligibilityIssue? issue;

  /// Abre el formulario del perfil. Sin él, el aviso no ofrece el botón (p. ej. si la pantalla no puede abrirlo).
  final VoidCallback? onCompleteProfile;

  const CategoryEligibilityNotice({super.key, required this.issue, this.onCompleteProfile});

  /// La clave del texto cuando el motivo no se conoce.
  static const unknownReasonKey = 'category_eligibility.notice.UNKNOWN';

  @override
  Widget build(BuildContext context) {
    context.locale;
    final showsAction = (issue?.needsProfileData ?? false) && onCompleteProfile != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: AppColors.warningLight, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('category_eligibility.notice_title'.tr(), style: AppTextStyles.cardTitle),
                    const SizedBox(height: AppSpacing.xs),
                    Text((issue?.noticeKey ?? unknownReasonKey).tr(), style: AppTextStyles.bodyMuted),
                  ],
                ),
              ),
            ],
          ),
          if (showsAction) ...[
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: onCompleteProfile,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warningLight,
                  side: const BorderSide(color: AppColors.warning),
                ),
                child: Text('category_eligibility.complete_profile'.tr()),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
