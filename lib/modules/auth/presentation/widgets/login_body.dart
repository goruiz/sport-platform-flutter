import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/core/constants/locale_keys.g.dart';
import 'package:sport_platform/core/constants/app_constants.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/modules/auth/presentation/widgets/auth_logo.dart';
import 'package:sport_platform/shared/widgets/social_button.dart';
import 'package:sport_platform/shared/widgets/sport_text_field.dart';

class LoginBody extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onLogin;
  final VoidCallback onTogglePassword;
  final VoidCallback? onSignUp;
  final VoidCallback? onForgotPassword;

  const LoginBody({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.onLogin,
    required this.onTogglePassword,
    this.onSignUp,
    this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Column(
      children: [
        const SizedBox(height: 48),
        const AuthLogo(),
        const SizedBox(height: 40),
        _buildHeader(),
        const SizedBox(height: 36),
        _buildForm(),
        const SizedBox(height: AppSpacing.md),
        _buildForgotPassword(),
        const SizedBox(height: AppSpacing.section),
        _buildLoginButton(),
        const SizedBox(height: AppSpacing.xxl),
        _buildDivider(),
        const SizedBox(height: AppSpacing.xxl),
        _buildSocialButtons(),
        const SizedBox(height: AppSpacing.xxxl),
        _buildSignUp(),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          LocaleKeys.login_welcome_back.tr(),
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          LocaleKeys.login_sign_in_subtitle.tr(),
          style: AppTextStyles.bodyMuted,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: formKey,
      child: AutofillGroup(
        child: Column(
          children: [
            SportTextField(
              controller: emailController,
              hint: LocaleKeys.login_email_hint.tr(),
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
            validator: (v) {
              if (v == null || v.isEmpty) {
                return LocaleKeys.login_email_required.tr();
              }
              if (!v.contains('@')) {
                return LocaleKeys.login_email_invalid.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          SportTextField(
            controller: passwordController,
            hint: LocaleKeys.login_password_hint.tr(),
            icon: Icons.lock_outline,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            // Enter en el teclado inicia sesión: no hace falta buscar el botón.
            onSubmitted: (_) {
              if (!isLoading) onLogin();
            },
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.whiteSubtle,
                size: 20,
              ),
              tooltip: LocaleKeys.login_show_hide_password.tr(),
              onPressed: onTogglePassword,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return LocaleKeys.login_password_required.tr();
              }
              if (v.length < AppConstants.minPasswordLength.value) {
                return LocaleKeys.login_password_too_short.tr(args: [AppConstants.minPasswordLength.asText]);
              }
              return null;
            },
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: onForgotPassword,
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        child: Text(
          LocaleKeys.login_forgot_password.tr(),
          style: const TextStyle(color: AppColors.primaryLight, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.button,
      child: FilledButton(
        onPressed: isLoading ? null : onLogin,
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(LocaleKeys.login_sign_in.tr()),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: AppColors.inputBorder, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            LocaleKeys.login_or_continue_with.tr(),
            style: AppTextStyles.footnote,
          ),
        ),
        const Expanded(
          child: Divider(color: AppColors.inputBorder, thickness: 1),
        ),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: SocialButton(
            label: LocaleKeys.login_google.tr(),
            icon: Icons.g_mobiledata,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: SocialButton(
            label: LocaleKeys.login_apple.tr(),
            icon: Icons.apple,
          ),
        ),
      ],
    );
  }

  Widget _buildSignUp() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          LocaleKeys.login_no_account.tr(),
          style: AppTextStyles.bodyMuted,
        ),
        TextButton(
          onPressed: onSignUp,
          child: Text(
            LocaleKeys.login_sign_up.tr(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
