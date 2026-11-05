import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/strings_constants/logout_strings_constants.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/services/session_service.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/auth/presentation/pages/login_page.dart';
import 'package:sport_platform/shared/widgets/confirmation_dialog.dart';

/// Cierra la sesión: pide confirmación, avisa al servidor (para invalidar el token) y vuelve al login.
/// Mientras tanto una ventana de espera impide tocar otra cosa. Se llama desde cualquier botón de «Cerrar sesión».
Future<void> confirmAndLogOut(BuildContext context) async {
  final confirmed = await showConfirmationDialog(
    context,
    title: LogoutStringsConstants.title.tr(),
    content: LogoutStringsConstants.confirm.tr(),
    confirmLabel: LogoutStringsConstants.button.tr(),
    cancelLabel: LogoutStringsConstants.cancel.tr(),
    destructive: false,
  );
  if (!confirmed || !context.mounted) return;

  final navigator = Navigator.of(context);
  _showBlockingSpinner(context);
  try {
    await DioClient().post(ApiEndpoints.logout);
  } catch (_) {
    // Si falla el aviso al servidor igual se limpia la sesión local.
  } finally {
    await getIt<SessionService>().clear();
  }

  navigator.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginPage()),
    (route) => false,
  );
}

void _showBlockingSpinner(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator(color: AppColors.primaryLight)),
    ),
  );
}
