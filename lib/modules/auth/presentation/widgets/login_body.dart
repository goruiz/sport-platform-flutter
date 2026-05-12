import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/strings_constants/auth_strings_constants/login_strings_constants.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
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
        const SizedBox(height: 12),
        _buildForgotPassword(),
        const SizedBox(height: 28),
        _buildLoginButton(),
        const SizedBox(height: 24),
        _buildDivider(),
        const SizedBox(height: 24),
        _buildSocialButtons(),
        const SizedBox(height: 32),
        _buildSignUp(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHeader() {
    return const Column(
      children: [
        Text(
          LoginStringsConstants.welcomeBack,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 8),
        Text(
          LoginStringsConstants.signInSubtitle,
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
            controller: emailController,
            hint: LoginStringsConstants.emailHint,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return LoginStringsConstants.emailRequired;
              if (!v.contains('@')) return LoginStringsConstants.emailInvalid;
              return null;
            },
          ),
          const SizedBox(height: 16),
          SportTextField(
            controller: passwordController,
            hint: LoginStringsConstants.passwordHint,
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
              if (v == null || v.isEmpty) return LoginStringsConstants.passwordRequired;
              if (v.length < 6) return LoginStringsConstants.passwordTooShort;
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        child: const Text(
          LoginStringsConstants.forgotPassword,
          style: TextStyle(color: AppColors.primaryLight, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onLogin,
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
                LoginStringsConstants.signIn,
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
            LoginStringsConstants.orContinueWith,
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
        Expanded(child: SocialButton(label: LoginStringsConstants.google, icon: Icons.g_mobiledata)),
        const SizedBox(width: 12),
        Expanded(child: SocialButton(label: LoginStringsConstants.apple, icon: Icons.apple)),
      ],
    );
  }

  Widget _buildSignUp() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          LoginStringsConstants.noAccount,
          style: TextStyle(color: AppColors.whiteSubtle, fontSize: 14),
        ),
        GestureDetector(
          onTap: onSignUp,
          child: const Text(
            LoginStringsConstants.signUp,
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
