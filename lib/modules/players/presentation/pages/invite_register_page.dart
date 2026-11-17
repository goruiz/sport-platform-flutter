import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/core/constants/locale_keys.g.dart';
import 'package:sport_platform/core/utils/app_logger.dart';
import 'package:sport_platform/core/constants/app_constants.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/auth/data/datasource/login_service.dart';
import 'package:sport_platform/core/routes/app_pages.dart';
import 'package:sport_platform/modules/players/data/datasource/players_auth_service.dart';
import 'package:sport_platform/shared/enums/category_eligibility_issue.dart';
import 'package:sport_platform/modules/players/domain/enums/team_invitation_error.dart';
import 'package:sport_platform/core/models/gender.dart';
import 'package:sport_platform/core/utils/name_rules.dart';
import 'package:sport_platform/modules/users/domain/profile_field_errors.dart';
import 'package:sport_platform/shared/widgets/person_name_input.dart';
import 'package:sport_platform/shared/widgets/birth_date_field.dart';
import 'package:sport_platform/shared/widgets/gender_field.dart';
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

  // El género y la fecha de nacimiento no son de texto: la categoría del equipo que invita puede pedirlos.
  Gender? _gender;
  DateTime? _birthDate;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  final _authService = PlayersAuthService();
  final _loginService = LoginService();

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
        firstName: normalizePersonName(_firstNameCtrl.text),
        lastName: normalizePersonName(_lastNameCtrl.text),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        inviteToken: widget.inviteToken,
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        gender: _gender,
        birthDate: _birthDate,
      );
      final isSignedIn = await _signInWithNewAccount();
      if (!mounted) return;
      _openAppAfterRegistering(isSignedIn: isSignedIn);
    } on DioException catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, _registerErrorKey(e).tr());
    } catch (error, stackTrace) {
      AppLogger.error('_InviteRegisterPageState._onRegister', error, stackTrace);
      if (!mounted) return;
      AppSnackbar.error(context, LocaleKeys.invite_register_error_generic.tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // El backend explica por qué rechaza el enlace con un código; sin código, un 409 es que el correo ya tiene cuenta.
  // La categoría del equipo puede no admitir a quien se registra (género, edad): se juzga antes de crear la cuenta, así que
  // no queda nada creado y puede corregir lo que dijo.
  String _registerErrorKey(DioException error) {
    final invitationError = TeamInvitationError.fromException(error);
    if (invitationError != null) return invitationError.registrationTranslationKey;
    final categoryIssue = CategoryEligibilityIssue.fromException(error);
    if (categoryIssue != null) return categoryIssue.refusalKey;
    final fieldErrors = ProfileFieldErrors.fromException(error);
    final dataError = fieldErrors.gender ?? fieldErrors.birthDate;
    if (dataError != null) return dataError.translationKey;
    if (error.response?.statusCode == 409) return LocaleKeys.invite_register_error_email_taken;
    return LocaleKeys.invite_register_error_generic;
  }

  // El backend crea la cuenta junto con el jugador: entra con la contraseña que acaba de elegir.
  // Si no se puede (p. ej. se cayó la red) la cuenta igual quedó creada, así que no es un error del registro.
  Future<bool> _signInWithNewAccount() async {
    try {
      await _loginService.signIn(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      return true;
    } catch (error) {
      AppLogger.warning('_InviteRegisterPageState._signInWithNewAccount', error);
      return false;
    }
  }

  void _openAppAfterRegistering({required bool isSignedIn}) {
    final messageKey =
        isSignedIn ? LocaleKeys.invite_register_success : LocaleKeys.invite_register_success_sign_in;
    AppSnackbar.success(context, messageKey.tr());
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => isSignedIn ? AppPages.home() : AppPages.login(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            children: [
              const SizedBox(height: 56),
              _buildHeader(),
              const SizedBox(height: AppSpacing.xl),
              _buildInviteBanner(),
              const SizedBox(height: AppSpacing.section),
              _buildForm(),
              const SizedBox(height: AppSpacing.section),
              _buildRegisterButton(),
              const SizedBox(height: AppSpacing.xxl),
              _buildSignIn(),
              const SizedBox(height: AppSpacing.xxxl),
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
        const SizedBox(height: AppSpacing.lg),
        Text(
          LocaleKeys.invite_register_title.tr(),
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
        borderRadius: BorderRadius.circular(AppRadius.md),
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
          const SizedBox(width: AppSpacing.snug),
          Expanded(
            child: Text(
              LocaleKeys.invite_register_subtitle.tr(),
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

  /// El motivo por el que un nombre o apellido no sirve, en el idioma activo; null si sirve.
  String? _nameError(String? value, {required String requiredKey}) {
    return switch (checkPersonName(value, required: true)) {
      null => null,
      PersonNameIssue.empty => requiredKey.tr(),
      PersonNameIssue.invalidCharacters => PersonNameIssue.invalidCharacters.translationKey!.tr(),
    };
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
                  hint: LocaleKeys.invite_register_first_name.tr(),
                  icon: Icons.person_outline,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: personNameInputFormatters,
                  validator: (v) => _nameError(v, requiredKey: LocaleKeys.invite_register_first_name_required),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: SportTextField(
                  controller: _lastNameCtrl,
                  hint: LocaleKeys.invite_register_last_name.tr(),
                  icon: Icons.person_outline,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: personNameInputFormatters,
                  validator: (v) => _nameError(v, requiredKey: LocaleKeys.invite_register_last_name_required),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          GenderField(value: _gender, onChanged: (gender) => setState(() => _gender = gender)),
          const SizedBox(height: AppSpacing.lg),
          BirthDateField(value: _birthDate, onChanged: (date) => setState(() => _birthDate = date)),
          const SizedBox(height: AppSpacing.lg),
          SportTextField(
            controller: _emailCtrl,
            hint: LocaleKeys.invite_register_email.tr(),
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return LocaleKeys.invite_register_email_required.tr();
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                return LocaleKeys.invite_register_email_invalid.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          SportTextField(
            controller: _passwordCtrl,
            hint: LocaleKeys.invite_register_password.tr(),
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
                return LocaleKeys.invite_register_password_required.tr();
              }
              if (v.length < AppConstants.minPasswordLength.value) {
                return LocaleKeys.invite_register_password_too_short.tr(args: [AppConstants.minPasswordLength.asText]);
              }
              final hasUpper = RegExp(r'[A-Z]').hasMatch(v);
              final hasLower = RegExp(r'[a-z]').hasMatch(v);
              final hasDigit = RegExp(r'\d').hasMatch(v);
              final hasSpecial =
                  RegExp(r'[!@#$%^&*(),.?":{}|<>\-_=+\[\]\\;`~]').hasMatch(v);
              if (!hasUpper || !hasLower || !hasDigit || !hasSpecial) {
                return LocaleKeys.invite_register_password_weak.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          SportTextField(
            controller: _confirmPasswordCtrl,
            hint: LocaleKeys.invite_register_confirm_password.tr(),
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
                return LocaleKeys.invite_register_confirm_password_required.tr();
              }
              if (v != _passwordCtrl.text) {
                return LocaleKeys.invite_register_passwords_mismatch.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          SportTextField(
            controller: _phoneCtrl,
            hint: LocaleKeys.invite_register_phone.tr(),
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
                LocaleKeys.invite_register_register_button.tr(),
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
          LocaleKeys.invite_register_already_have_account.tr(),
          style: AppTextStyles.bodyMuted,
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => AppPages.login()),
            (_) => false,
          ),
          child: Text(
            LocaleKeys.invite_register_sign_in.tr(),
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
