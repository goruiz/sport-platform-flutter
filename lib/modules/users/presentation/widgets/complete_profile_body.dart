import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/strings_constants/profile_strings_constants.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/shared/widgets/sport_text_field.dart';

class CompleteProfileBody extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController middleNameController;
  final TextEditingController lastNameController;
  final TextEditingController secondLastNameController;
  final TextEditingController usernameController;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback? onSkip;

  const CompleteProfileBody({
    super.key,
    required this.formKey,
    required this.firstNameController,
    required this.middleNameController,
    required this.lastNameController,
    required this.secondLastNameController,
    required this.usernameController,
    required this.isLoading,
    required this.onSubmit,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 48),
        _buildHeader(),
        const SizedBox(height: 32),
        _buildProgressIndicator(),
        const SizedBox(height: 32),
        _buildForm(),
        const SizedBox(height: 28),
        _buildSubmitButton(),
        const SizedBox(height: 16),
        _buildSkipButton(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ProfileStringsConstants.title.tr(),
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          ProfileStringsConstants.subtitle.tr(),
          style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        _buildStep(label: ProfileStringsConstants.stepAccount.tr(), isCompleted: true),
        _buildStepConnector(isCompleted: true),
        _buildStep(label: ProfileStringsConstants.stepProfile.tr(), isActive: true),
        _buildStepConnector(isCompleted: false),
        _buildStep(label: ProfileStringsConstants.stepDone.tr()),
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
        const SizedBox(height: 4),
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
                child: SportTextField(
                  controller: firstNameController,
                  hint: ProfileStringsConstants.firstName.tr(),
                  icon: Icons.person_outline,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return ProfileStringsConstants.required.tr();
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SportTextField(
                  controller: middleNameController,
                  hint: ProfileStringsConstants.middleName.tr(),
                  icon: Icons.person_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SportTextField(
                  controller: lastNameController,
                  hint: ProfileStringsConstants.lastName.tr(),
                  icon: Icons.badge_outlined,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return ProfileStringsConstants.required.tr();
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SportTextField(
                  controller: secondLastNameController,
                  hint: ProfileStringsConstants.secondLastName.tr(),
                  icon: Icons.badge_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SportTextField(
            controller: usernameController,
            hint: ProfileStringsConstants.username.tr(),
            icon: Icons.alternate_email,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return ProfileStringsConstants.required.tr();
              if (v.trim().length < 3) return ProfileStringsConstants.usernameTooShort.tr();
              if (v.contains(' ')) return ProfileStringsConstants.usernameNoSpaces.tr();
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onSubmit,
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
                ProfileStringsConstants.saveButton.tr(),
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
          ProfileStringsConstants.skipButton.tr(),
          style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 14),
        ),
      ),
    );
  }
}
