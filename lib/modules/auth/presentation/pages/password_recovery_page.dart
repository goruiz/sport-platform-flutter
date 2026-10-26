import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/strings_constants/auth_strings_constants/login_strings_constants.dart';
import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/services/auth_storage.dart';
import 'package:sport_platform/core/services/user_session.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/auth/presentation/widgets/auth_logo.dart';
import 'package:sport_platform/shared/widgets/app_snackbar.dart';
import 'package:sport_platform/shared/widgets/gradient_background.dart';
import 'package:sport_platform/shared/widgets/sport_text_field.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _client = DioClient();
  bool _isLoading = false;
  bool _requestSubmitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _client.post(
        ApiEndpoints.forgotPassword,
        data: {'email': _emailController.text.trim()},
      );
      if (!mounted) return;
      setState(() => _requestSubmitted = true);
    } on DioException {
      if (!mounted) return;
      AppSnackbar.error(context, LoginStringsConstants.recoveryError.tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _RecoveryScaffold(
      title: LoginStringsConstants.recoveryTitle.tr(),
      subtitle: LoginStringsConstants.recoverySubtitle.tr(),
      child: _requestSubmitted
          ? Text(
              LoginStringsConstants.recoverySent.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.white, fontSize: 15),
            )
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  SportTextField(
                    controller: _emailController,
                    hint: LoginStringsConstants.emailHint.tr(),
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 22),
                  _PrimaryButton(
                    label: LoginStringsConstants.recoverySend.tr(),
                    isLoading: _isLoading,
                    onPressed: _requestReset,
                  ),
                ],
              ),
            ),
    );
  }
}

class ResetPasswordPage extends StatefulWidget {
  final String token;
  final VoidCallback onCompleted;
  final VoidCallback onBack;

  const ResetPasswordPage({
    super.key,
    required this.token,
    required this.onCompleted,
    required this.onBack,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _client = DioClient();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _client.post(
        ApiEndpoints.resetPassword,
        data: {'token': widget.token, 'newPassword': _passwordController.text},
      );
      await AuthStorage.clearToken();
      await UserSession.clear();
      if (!mounted) return;
      AppSnackbar.success(context, LoginStringsConstants.resetSuccess.tr());
      widget.onCompleted();
    } on DioException catch (error) {
      if (!mounted) return;
      final data = error.response?.data;
      final fieldErrors = data is Map<String, dynamic> ? data['data'] : null;
      final tokenError =
          fieldErrors is Map<String, dynamic> &&
          fieldErrors['token'] == 'INVALID_OR_EXPIRED';
      AppSnackbar.error(
        context,
        (tokenError
                ? LoginStringsConstants.resetTokenInvalid
                : LoginStringsConstants.resetError)
            .tr(),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _RecoveryScaffold(
      title: LoginStringsConstants.resetTitle.tr(),
      subtitle: LoginStringsConstants.resetSubtitle.tr(),
      onBack: widget.onBack,
      child: widget.token.isEmpty
          ? Text(
              LoginStringsConstants.resetTokenInvalid.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.white, fontSize: 15),
            )
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  SportTextField(
                    controller: _passwordController,
                    hint: LoginStringsConstants.newPasswordHint.tr(),
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.whiteSubtle,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 16),
                  SportTextField(
                    controller: _confirmPasswordController,
                    hint: LoginStringsConstants.confirmPasswordHint.tr(),
                    icon: Icons.lock_reset_outlined,
                    obscureText: _obscureConfirmation,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmation
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.whiteSubtle,
                        size: 20,
                      ),
                      onPressed: () => setState(
                        () => _obscureConfirmation = !_obscureConfirmation,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return LoginStringsConstants.passwordRequired.tr();
                      }
                      if (value != _passwordController.text) {
                        return LoginStringsConstants.passwordsDoNotMatch.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 22),
                  _PrimaryButton(
                    label: LoginStringsConstants.resetPassword.tr(),
                    isLoading: _isLoading,
                    onPressed: _resetPassword,
                  ),
                ],
              ),
            ),
    );
  }
}

class _RecoveryScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;

  const _RecoveryScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    const AuthLogo(),
                    const SizedBox(height: 36),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.whiteSubtle,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 30),
                    child,
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed:
                          onBack ?? () => Navigator.of(context).maybePop(),
                      child: Text(LoginStringsConstants.backToLogin.tr()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

String? _validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return LoginStringsConstants.emailRequired.tr();
  }
  if (!value.contains('@')) return LoginStringsConstants.emailInvalid.tr();
  return null;
}

String? _validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return LoginStringsConstants.passwordRequired.tr();
  }
  if (value.length < 8) return LoginStringsConstants.passwordTooShort.tr();
  if (value.length > 72) return LoginStringsConstants.passwordTooLong.tr();
  return null;
}
