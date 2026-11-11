import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/modules/players/domain/enums/category_eligibility_issue.dart';
import 'package:sport_platform/modules/users/domain/entities/user_entity.dart';
import 'package:sport_platform/modules/users/presentation/pages/complete_profile_page.dart';
import 'package:sport_platform/shared/widgets/app_snackbar.dart';
import 'package:sport_platform/shared/widgets/confirmation_dialog.dart';

/// Abre el formulario para editar el perfil. Devuelve true si la persona guardó cambios (el backend vuelve a juzgar su
/// elegibilidad con los datos nuevos, así que quien la abrió debería volver a leer lo suyo).
Future<bool> openProfileEditor(BuildContext context) async {
  final updated = await Navigator.of(context).push<UserEntity>(
    MaterialPageRoute(builder: (_) => const CompleteProfilePage(editing: true)),
  );
  return updated != null;
}

/// Explica por qué la categoría del equipo no dejó entrar a la persona (aceptando una invitación, con un código o al
/// registrarse con el enlace).
///
/// Un «no» de la categoría (género, edad) se dice con un aviso. Si lo que falta son datos del perfil se ofrece, en un
/// diálogo, ir a completarlos: es lo que la persona puede hacer en ese momento. Devuelve true si completó su perfil, para
/// que quien llamó pueda intentar de nuevo.
Future<bool> showCategoryRefusal(BuildContext context, CategoryEligibilityIssue issue) async {
  if (!issue.needsProfileData) {
    AppSnackbar.error(context, issue.refusalKey.tr());
    return false;
  }
  final wantsToComplete = await showConfirmationDialog(
    context,
    title: 'category_eligibility.refused_title'.tr(),
    content: issue.refusalKey.tr(),
    confirmLabel: 'category_eligibility.complete_profile'.tr(),
    cancelLabel: 'category_eligibility.not_now'.tr(),
    destructive: false,
  );
  if (!wantsToComplete || !context.mounted) return false;
  return openProfileEditor(context);
}
