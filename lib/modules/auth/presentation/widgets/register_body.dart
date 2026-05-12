import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/auth_constants/register_strings_constants.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/auth/presentation/widgets/auth_logo.dart';
import 'package:sport_platform/shared/widgets/social_button.dart';
import 'package:sport_platform/shared/widgets/sport_text_field.dart';

class RegisterBody extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool isLoading;
  final VoidCallback onRegister;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onSignIn;

  const RegisterBody({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.isLoading,
    required this.onRegister,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
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
    return const Column(
      children: [
        Text(
          RegisterStringsConstants.createAccount,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 8),
        Text(
          RegisterStringsConstants.signUpSubtitle,
          style: TextStyle(color: AppColors.whiteSubtle, fontSize: 14),
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
            controller: nameController,
            hint: RegisterStringsConstants.fullNameHint,
            icon: Icons.person_outline,
            keyboardType: TextInputType.name,
            validator: (v) {
              if (v == null || v.isEmpty) return RegisterStringsConstants.nameRequired;
              if (v.trim().length < 2) return RegisterStringsConstants.nameTooShort;
              return null;
            },
          ),
          const SizedBox(height: 16),
          SportTextField(
            controller: emailController,
            hint: RegisterStringsConstants.emailHint,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return RegisterStringsConstants.emailRequired;
              if (!v.contains('@')) return RegisterStringsConstants.emailInvalid;
              return null;
            },
          ),
          const SizedBox(height: 16),
          SportTextField(
            controller: passwordController,
            hint: RegisterStringsConstants.passwordHint,
            icon: Icons.lock_outline,
            obscureText: obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.whiteSubtle,
                size: 20,
              ),
              onPressed: onTogglePassword,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return RegisterStringsConstants.passwordRequired;
              if (v.length < 6) return RegisterStringsConstants.passwordTooShort;
              return null;
            },
          ),
          const SizedBox(height: 16),
          SportTextField(
            controller: confirmPasswordController,
            hint: RegisterStringsConstants.confirmPasswordHint,
            icon: Icons.lock_outline,
            obscureText: obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.whiteSubtle,
                size: 20,
              ),
              onPressed: onToggleConfirmPassword,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return RegisterStringsConstants.confirmPasswordRequired;
              if (v != passwordController.text) return RegisterStringsConstants.passwordsDoNotMatch;
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
            : const Text(
                RegisterStringsConstants.signUpButton,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.inputBorder, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            RegisterStringsConstants.orContinueWith,
            style: TextStyle(color: AppColors.whiteSubtle, fontSize: 12),
          ),
        ),
        Expanded(child: Divider(color: AppColors.inputBorder, thickness: 1)),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(child: SocialButton(label: RegisterStringsConstants.google, icon: Icons.g_mobiledata)),
        const SizedBox(width: 12),
        Expanded(child: SocialButton(label: RegisterStringsConstants.apple, icon: Icons.apple)),
      ],
    );
  }

  Widget _buildSignIn() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          RegisterStringsConstants.alreadyHaveAccount,
          style: TextStyle(color: AppColors.whiteSubtle, fontSize: 14),
        ),
        GestureDetector(
          onTap: onSignIn,
          child: const Text(
            RegisterStringsConstants.signInLink,
            style: TextStyle(
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
