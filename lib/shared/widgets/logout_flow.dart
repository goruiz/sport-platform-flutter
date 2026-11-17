import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/locale_keys.g.dart';
import 'package:sport_platform/core/utils/app_logger.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/services/session_service.dart';
import 'package:sport_platform/core/routes/app_pages.dart';
import 'package:sport_platform/shared/widgets/confirmation_dialog.dart';

/// Cierra la sesión: pide confirmación, avisa al servidor (para invalidar el token) y vuelve al login.
/// Mientras tanto una ventana de espera impide tocar otra cosa. Se llama desde cualquier botón de «Cerrar sesión».
Future<void> confirmAndLogOut(BuildContext context) async {
  final confirmed = await showConfirmationDialog(
    context,
    title: LocaleKeys.logout_title.tr(),
    content: LocaleKeys.logout_confirm.tr(),
    confirmLabel: LocaleKeys.logout_button.tr(),
    cancelLabel: LocaleKeys.logout_cancel.tr(),
    destructive: false,
  );
  if (!confirmed || !context.mounted) return;

  final navigator = Navigator.of(context);
  _showBlockingSpinner(context);
  try {
    await DioClient().post(ApiEndpoints.logout);
  } catch (error) {
    AppLogger.warning('confirmAndLogOut', error);
    // Si falla el aviso al servidor igual se limpia la sesión local.
  } finally {
    await getIt<SessionService>().clear();
  }

  navigator.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => AppPages.login()),
    (route) => false,
  );
}

void _showBlockingSpinner(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  );
}
