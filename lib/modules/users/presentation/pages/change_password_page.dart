import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/app_constants.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/users/data/datasource/account_service.dart';
import 'package:sport_platform/modules/users/domain/enums/account_error.dart';
import 'package:sport_platform/modules/users/domain/password_rules.dart';
import 'package:sport_platform/shared/widgets/app_snackbar.dart';
import 'package:sport_platform/shared/widgets/sport_text_field.dart';

/// Cambiar la contraseña con sesión iniciada: pide la actual, la nueva y su confirmación.
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _hidePasswords = true;
  bool _saving = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await getIt<AccountService>().changePassword(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      );
      if (!mounted) return;
      AppSnackbar.success(context, 'account.change_password.success'.tr());
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      final reason = AccountError.fromException(error);
      AppSnackbar.error(context, (reason?.translationKey ?? 'account.errors.generic').tr());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _messageOf(PasswordIssue? issue) {
    if (issue == null) return null;
    return switch (issue) {
      PasswordIssue.tooShort => issue.translationKey.tr(args: ['${AppConstants.minPasswordLength}']),
      PasswordIssue.tooLong => issue.translationKey.tr(args: ['${AppConstants.maxPasswordLength}']),
      _ => issue.translationKey.tr(),
    };
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hintKey,
    required String? Function(String?) validator,
  }) {
    return SportTextField(
      controller: controller,
      hint: hintKey.tr(),
      icon: Icons.lock_outline,
      obscureText: _hidePasswords,
      validator: validator,
      suffixIcon: IconButton(
        icon: Icon(
          _hidePasswords ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.whiteSubtle,
          size: 20,
        ),
        onPressed: () => setState(() => _hidePasswords = !_hidePasswords),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Scaffold(
      backgroundColor: AppColors.backgroundEnd,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text(
          'account.change_password.title'.tr(),
          style: const TextStyle(color: AppColors.white),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _passwordField(
              controller: _currentController,
              hintKey: 'account.change_password.current',
              validator: (value) => (value ?? '').isEmpty
                  ? PasswordIssue.empty.translationKey.tr()
                  : null,
            ),
            const SizedBox(height: 16),
            _passwordField(
              controller: _newController,
              hintKey: 'account.change_password.new',
              validator: (value) => _messageOf(
                checkNewPassword(value ?? '', currentPassword: _currentController.text),
              ),
            ),
            const SizedBox(height: 16),
            _passwordField(
              controller: _confirmController,
              hintKey: 'account.change_password.confirm',
              validator: (value) => _messageOf(checkConfirmation(_newController.text, value ?? '')),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2.5),
                      )
                    : Text('account.change_password.submit'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
