import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/constants/locale_keys.g.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/routes/app_navigator.dart';
import 'package:sport_platform/core/services/session_service.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/routes/app_pages.dart';
import 'package:sport_platform/modules/users/data/datasource/account_service.dart';
import 'package:sport_platform/modules/users/domain/enums/account_error.dart';
import 'package:sport_platform/shared/widgets/app_snackbar.dart';
import 'package:sport_platform/shared/widgets/confirmation_dialog.dart';
import 'package:sport_platform/shared/widgets/sport_text_field.dart';

/// Eliminar la cuenta: se borran los datos personales y el jugador sale de su equipo. No se puede deshacer, así que
/// pide la contraseña y una confirmación.
class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _passwordController = TextEditingController();
  bool _hidePassword = true;
  bool _deleting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_passwordController.text.isEmpty) {
      AppSnackbar.error(context, LocaleKeys.account_validation_empty.tr());
      return;
    }
    final confirmed = await showConfirmationDialog(
      context,
      title: LocaleKeys.account_delete_confirm_title.tr(),
      content: LocaleKeys.account_delete_confirm_text.tr(),
      confirmLabel: LocaleKeys.account_delete_confirm_button.tr(),
      cancelLabel: LocaleKeys.common_cancel.tr(),
    );
    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    try {
      await getIt<AccountService>().deleteAccount(password: _passwordController.text);
    } catch (error) {
      if (!mounted) return;
      final reason = AccountError.fromException(error);
      AppSnackbar.error(context, (reason?.translationKey ?? LocaleKeys.account_errors_generic).tr());
      setState(() => _deleting = false);
      return;
    }
    await _leaveTheApp();
  }

  /// La cuenta ya no existe: se limpia la sesión local y se vuelve al login con un aviso.
  Future<void> _leaveTheApp() async {
    await getIt<SessionService>().clear();
    final navigator = AppNavigator.key.currentState;
    navigator?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => AppPages.login()),
      (route) => false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = AppNavigator.key.currentContext;
      if (context != null) AppSnackbar.success(context, LocaleKeys.account_delete_done.tr());
    });
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Scaffold(
      backgroundColor: AppColors.backgroundEnd,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text(LocaleKeys.account_delete_title.tr(), style: const TextStyle(color: AppColors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    LocaleKeys.account_delete_warning.tr(),
                    style: const TextStyle(color: AppColors.white, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          SportTextField(
            controller: _passwordController,
            hint: LocaleKeys.account_delete_password.tr(),
            icon: Icons.lock_outline,
            obscureText: _hidePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _hidePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.whiteSubtle,
                size: 20,
              ),
              onPressed: () => setState(() => _hidePassword = !_hidePassword),
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _deleting ? null : _delete,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.compact)),
              ),
              child: _deleting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2.5),
                    )
                  : Text(LocaleKeys.account_delete_button.tr()),
            ),
          ),
        ],
      ),
    );
  }
}
