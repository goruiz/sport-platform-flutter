import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/strings_constants/auth_strings_constants/register_strings_constants.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
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
        const SizedBox(height: 28),
        _buildRegisterButton(),
        const SizedBox(height: 24),
        _buildDivider(),
        const SizedBox(height: 24),
        _buildSocialButtons(),
        const SizedBox(height: 32),
        _buildSignIn(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          RegisterStringsConstants.createAccount.tr(),
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          RegisterStringsConstants.signUpSubtitle.tr(),
          style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: formKey,
      child: Column(
        children: [
          const SizedBox(height: 16),
          SportTextField(
            controller: emailController,
            hint: RegisterStringsConstants.emailHint.tr(),
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return RegisterStringsConstants.emailRequired.tr();
              if (!v.contains('@')) return RegisterStringsConstants.emailInvalid.tr();
              return null;
            },
          ),
          const SizedBox(height: 16),
          SportTextField(
            controller: passwordController,
            hint: RegisterStringsConstants.passwordHint.tr(),
            icon: Icons.lock_outline,
            obscureText: showPassword,
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
              if (v == null || v.isEmpty) return RegisterStringsConstants.passwordRequired.tr();
              if (v.length < 8) return RegisterStringsConstants.passwordTooShort.tr();
              final hasUpper = RegExp(r'[A-Z]').hasMatch(v);
              final hasLower = RegExp(r'[a-z]').hasMatch(v);
              final hasDigit = RegExp(r'\d').hasMatch(v);
              final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>\-_=+\[\]\\;`~]').hasMatch(v);
              if (!hasUpper || !hasLower || !hasDigit || !hasSpecial) {
                return RegisterStringsConstants.passwordWeak.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          SportTextField(
            controller: confirmPasswordController,
            hint: RegisterStringsConstants.confirmPasswordHint.tr(),
            icon: Icons.lock_outline,
            obscureText: showConfirmPassword,
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
              if (v == null || v.isEmpty) return RegisterStringsConstants.confirmPasswordRequired.tr();
              if (v != passwordController.text) return RegisterStringsConstants.passwordsDoNotMatch.tr();
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
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.primaryLight.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
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
                RegisterStringsConstants.signUpButton.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.inputBorder, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            RegisterStringsConstants.orContinueWith.tr(),
            style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 12),
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
            label: RegisterStringsConstants.google.tr(),
            icon: Icons.g_mobiledata,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SocialButton(
            label: RegisterStringsConstants.apple.tr(),
            icon: Icons.apple,
          ),
        ),
      ],
    );
  }

  Widget _buildSignIn() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          RegisterStringsConstants.alreadyHaveAccount.tr(),
          style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 14),
        ),
        GestureDetector(
          onTap: onSignIn,
          child: Text(
            RegisterStringsConstants.signInLink.tr(),
            style: const TextStyle(
              color: AppColors.primaryLight,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
