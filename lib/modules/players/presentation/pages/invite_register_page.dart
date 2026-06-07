import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/auth/presentation/pages/login_page.dart';
import 'package:sport_platform/modules/players/data/datasource/players_auth_service.dart';
import 'package:sport_platform/shared/widgets/app_snackbar.dart';
import 'package:sport_platform/shared/widgets/gradient_background.dart';
import 'package:sport_platform/shared/widgets/sport_text_field.dart';

class InviteRegisterPage extends StatefulWidget {
  final String inviteToken;

  const InviteRegisterPage({super.key, required this.inviteToken});

  @override
  State<InviteRegisterPage> createState() => _InviteRegisterPageState();
}

class _InviteRegisterPageState extends State<InviteRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  final _authService = PlayersAuthService();

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _authService.registerWithToken(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        inviteToken: widget.inviteToken,
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      );
      if (!mounted) return;
      AppSnackbar.success(context, 'invite_register.success'.tr());
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final body = e.response?.data;
      final message = body is Map ? (body['message'] as String? ?? '') : '';
      final lower = message.toLowerCase();

      if (lower.contains('already been used') || lower.contains('expired')) {
        AppSnackbar.error(context, 'invite_register.error_token_used'.tr());
      } else if (lower.contains('invalid invitation token')) {
        AppSnackbar.error(context, 'invite_register.error_token_invalid'.tr());
      } else if (e.response?.statusCode == 409) {
        AppSnackbar.error(context, 'invite_register.error_email_taken'.tr());
      } else {
        AppSnackbar.error(context, 'invite_register.error_generic'.tr());
      }
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error(context, 'invite_register.error_generic'.tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 56),
              _buildHeader(),
              const SizedBox(height: 20),
              _buildInviteBanner(),
              const SizedBox(height: 28),
              _buildForm(),
              const SizedBox(height: 28),
              _buildRegisterButton(),
              const SizedBox(height: 24),
              _buildSignIn(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Icon(Icons.sports, color: AppColors.primaryLight, size: 52),
        const SizedBox(height: 16),
        Text(
          'invite_register.title'.tr(),
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInviteBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.mark_email_unread_outlined,
            color: AppColors.primaryLight,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'invite_register.subtitle'.tr(),
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SportTextField(
                  controller: _firstNameCtrl,
                  hint: 'invite_register.first_name'.tr(),
                  icon: Icons.person_outline,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'invite_register.first_name_required'.tr()
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SportTextField(
                  controller: _lastNameCtrl,
                  hint: 'invite_register.last_name'.tr(),
                  icon: Icons.person_outline,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'invite_register.last_name_required'.tr()
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SportTextField(
            controller: _emailCtrl,
            hint: 'invite_register.email'.tr(),
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'invite_register.email_required'.tr();
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                return 'invite_register.email_invalid'.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          SportTextField(
            controller: _passwordCtrl,
            hint: 'invite_register.password'.tr(),
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
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'invite_register.password_required'.tr();
              }
              if (v.length < 8) return 'invite_register.password_too_short'.tr();
              final hasUpper = RegExp(r'[A-Z]').hasMatch(v);
              final hasLower = RegExp(r'[a-z]').hasMatch(v);
              final hasDigit = RegExp(r'\d').hasMatch(v);
              final hasSpecial =
                  RegExp(r'[!@#$%^&*(),.?":{}|<>\-_=+\[\]\\;`~]').hasMatch(v);
              if (!hasUpper || !hasLower || !hasDigit || !hasSpecial) {
                return 'invite_register.password_weak'.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          SportTextField(
            controller: _confirmPasswordCtrl,
            hint: 'invite_register.confirm_password'.tr(),
            icon: Icons.lock_outline,
            obscureText: _obscureConfirm,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.whiteSubtle,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'invite_register.confirm_password_required'.tr();
              }
              if (v != _passwordCtrl.text) {
                return 'invite_register.passwords_mismatch'.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          SportTextField(
            controller: _phoneCtrl,
            hint: 'invite_register.phone'.tr(),
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
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
        onPressed: _isLoading ? null : _onRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.white,
          disabledBackgroundColor:
              AppColors.primaryLight.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                'invite_register.register_button'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildSignIn() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'invite_register.already_have_account'.tr(),
          style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 14),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (_) => false,
          ),
          child: Text(
            'invite_register.sign_in'.tr(),
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
