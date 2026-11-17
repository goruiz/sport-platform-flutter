import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/core/constants/locale_keys.g.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/models/gender.dart';
import 'package:sport_platform/core/utils/name_rules.dart';
import 'package:sport_platform/shared/widgets/person_name_input.dart';
import 'package:sport_platform/shared/widgets/birth_date_field.dart';
import 'package:sport_platform/shared/widgets/gender_field.dart';
import 'package:sport_platform/shared/widgets/sport_text_field.dart';

class CompleteProfileBody extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController middleNameController;
  final TextEditingController lastNameController;
  final TextEditingController secondLastNameController;
  final TextEditingController usernameController;

  /// El género y la fecha de nacimiento no son de texto: la pantalla guarda su valor y este formulario solo los dibuja.
  final Gender? gender;
  final ValueChanged<Gender> onGenderChanged;
  final DateTime? birthDate;
  final ValueChanged<DateTime> onBirthDateChanged;

  /// Lo que el backend dijo de cada uno, ya traducido (null si no dijo nada).
  final String? genderServerError;
  final String? birthDateServerError;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback? onSkip;
  final bool editing;

  const CompleteProfileBody({
    super.key,
    required this.formKey,
    required this.firstNameController,
    required this.middleNameController,
    required this.lastNameController,
    required this.secondLastNameController,
    required this.usernameController,
    required this.gender,
    required this.onGenderChanged,
    required this.birthDate,
    required this.onBirthDateChanged,
    this.genderServerError,
    this.birthDateServerError,
    required this.isLoading,
    required this.onSubmit,
    this.onSkip,
    this.editing = false,
  });

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 48),
        _buildHeader(),
        if (!editing) ...[
          const SizedBox(height: AppSpacing.xxxl),
          _buildProgressIndicator(),
          const SizedBox(height: AppSpacing.xxxl),
        ] else
          const SizedBox(height: AppSpacing.xxl),
        _buildForm(),
        const SizedBox(height: AppSpacing.section),
        _buildSubmitButton(),
        if (onSkip != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _buildSkipButton(),
        ],
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          (editing
                  ? LocaleKeys.profile_edit_title
                  : LocaleKeys.profile_title)
              .tr(),
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          (editing
                  ? LocaleKeys.profile_edit_subtitle
                  : LocaleKeys.profile_subtitle)
              .tr(),
          style: AppTextStyles.bodyMuted,
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        _buildStep(label: LocaleKeys.profile_step_account.tr(), isCompleted: true),
        _buildStepConnector(isCompleted: true),
        _buildStep(label: LocaleKeys.profile_step_profile.tr(), isActive: true),
        _buildStepConnector(isCompleted: false),
        _buildStep(label: LocaleKeys.profile_step_done.tr()),
      ],
    );
  }

  Widget _buildStep({
    required String label,
    bool isCompleted = false,
    bool isActive = false,
  }) {
    final Color color = isCompleted || isActive
        ? AppColors.primaryLight
        : AppColors.inputBorder;

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isCompleted ? AppColors.primaryLight : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: isCompleted
              ? const Icon(Icons.check, color: AppColors.white, size: 16)
              : isActive
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: TextStyle(
            color: isCompleted || isActive
                ? AppColors.primaryLight
                : AppColors.whiteSubtle,
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector({required bool isCompleted}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        color: isCompleted ? AppColors.primaryLight : AppColors.inputBorder,
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: formKey,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildNameField(
                  controller: firstNameController,
                  hint: LocaleKeys.profile_first_name.tr(),
                  icon: Icons.person_outline,
                  isRequired: true,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildNameField(
                  controller: middleNameController,
                  hint: LocaleKeys.profile_middle_name.tr(),
                  icon: Icons.person_outline,
                  isRequired: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _buildNameField(
                  controller: lastNameController,
                  hint: LocaleKeys.profile_last_name.tr(),
                  icon: Icons.badge_outlined,
                  isRequired: true,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildNameField(
                  controller: secondLastNameController,
                  hint: LocaleKeys.profile_second_last_name.tr(),
                  icon: Icons.badge_outlined,
                  isRequired: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SportTextField(
            controller: usernameController,
            hint: LocaleKeys.profile_username.tr(),
            icon: Icons.alternate_email,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return LocaleKeys.profile_required.tr();
              if (v.trim().length < 3) return LocaleKeys.profile_username_too_short.tr();
              if (v.contains(' ')) return LocaleKeys.profile_username_no_spaces.tr();
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          GenderField(value: gender, onChanged: onGenderChanged, serverError: genderServerError),
          const SizedBox(height: AppSpacing.lg),
          BirthDateField(value: birthDate, onChanged: onBirthDateChanged, serverError: birthDateServerError),
        ],
      ),
    );
  }

  /// Un nombre o apellido: el teclado no deja escribir números ni símbolos y el validador revisa lo que quede.
  Widget _buildNameField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isRequired,
  }) {
    return SportTextField(
      controller: controller,
      hint: hint,
      icon: icon,
      textCapitalization: TextCapitalization.words,
      inputFormatters: personNameInputFormatters,
      validator: (value) => _nameErrorText(checkPersonName(value, required: isRequired)),
    );
  }

  String? _nameErrorText(PersonNameIssue? issue) => switch (issue) {
        null => null,
        PersonNameIssue.empty => LocaleKeys.profile_required.tr(),
        PersonNameIssue.invalidCharacters => PersonNameIssue.invalidCharacters.translationKey!.tr(),
      };

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onSubmit,
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
                (editing
                        ? LocaleKeys.profile_update_button
                        : LocaleKeys.profile_save_button)
                    .tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return Center(
      child: TextButton(
        onPressed: onSkip,
        child: Text(
          LocaleKeys.profile_skip_button.tr(),
          style: AppTextStyles.bodyMuted,
        ),
      ),
    );
  }
}
