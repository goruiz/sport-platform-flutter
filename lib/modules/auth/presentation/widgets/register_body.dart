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

class RegisterBody extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool showPassword;
  final bool showConfirmPassword;
  final bool isLoading;
  final VoidCallback onRegister;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onSignIn;

  const RegisterBody({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.showPassword,
    required this.showConfirmPassword,
    required this.isLoading,
    required this.onRegister,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onSignIn,
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
        const SizedBox(height: AppSpacing.section),
        _buildRegisterButton(),
        const SizedBox(height: AppSpacing.xxl),
        _buildDivider(),
        const SizedBox(height: AppSpacing.xxl),
        _buildSocialButtons(),
        const SizedBox(height: AppSpacing.xxxl),
        _buildSignIn(),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          LocaleKeys.register_create_account.tr(),
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          LocaleKeys.register_sign_up_subtitle.tr(),
          style: AppTextStyles.bodyMuted,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: formKey,
      child: Column(
        children: [
          SportTextField(
            controller: emailController,
            hint: LocaleKeys.register_email_hint.tr(),
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: (v) {
              if (v == null || v.isEmpty) return LocaleKeys.register_email_required.tr();
              if (!v.contains('@')) return LocaleKeys.register_email_invalid.tr();
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          SportTextField(
            controller: passwordController,
            hint: LocaleKeys.register_password_hint.tr(),
            icon: Icons.lock_outline,
            obscureText: showPassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            // Las reglas se dicen antes de teclear, no solo cuando la contraseña ya fue rechazada.
            helperText: LocaleKeys.register_password_rules.tr(args: [AppConstants.minPasswordLength.asText]),
            suffixIcon: IconButton(
              icon: Icon(
                showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.whiteSubtle,
                size: 20,
              ),
              onPressed: onTogglePassword,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return LocaleKeys.register_password_required.tr();
              if (v.length < AppConstants.minPasswordLength.value) {
                return LocaleKeys.register_password_too_short.tr(args: [AppConstants.minPasswordLength.asText]);
              }
              final hasUpper = RegExp(r'[A-Z]').hasMatch(v);
              final hasLower = RegExp(r'[a-z]').hasMatch(v);
              final hasDigit = RegExp(r'\d').hasMatch(v);
              final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>\-_=+\[\]\\;`~]').hasMatch(v);
              if (!hasUpper || !hasLower || !hasDigit || !hasSpecial) {
                return LocaleKeys.register_password_weak.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          SportTextField(
            controller: confirmPasswordController,
            hint: LocaleKeys.register_confirm_password_hint.tr(),
            icon: Icons.lock_outline,
            obscureText: showConfirmPassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!isLoading) onRegister();
            },
            suffixIcon: IconButton(
              icon: Icon(
                showConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.whiteSubtle,
                size: 20,
              ),
              onPressed: onToggleConfirmPassword,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return LocaleKeys.register_confirm_password_required.tr();
              if (v != passwordController.text) return LocaleKeys.register_passwords_do_not_match.tr();
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.button,
      child: FilledButton(
        onPressed: isLoading ? null : onRegister,
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(LocaleKeys.register_sign_up_button.tr()),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.inputBorder, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            LocaleKeys.register_or_continue_with.tr(),
            style: AppTextStyles.footnote,
          ),
        ),
        const Expanded(child: Divider(color: AppColors.inputBorder, thickness: 1)),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: SocialButton(
            label: LocaleKeys.register_google.tr(),
            icon: Icons.g_mobiledata,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: SocialButton(
            label: LocaleKeys.register_apple.tr(),
            icon: Icons.apple,
          ),
        ),
      ],
    );
  }

  Widget _buildSignIn() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          LocaleKeys.register_already_have_account.tr(),
          style: AppTextStyles.bodyMuted,
        ),
        TextButton(
          onPressed: onSignIn,
          child: Text(
            LocaleKeys.register_sign_in_link.tr(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
