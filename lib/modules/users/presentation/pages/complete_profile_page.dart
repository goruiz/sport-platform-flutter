import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/strings_constants/profile_strings_constants.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/services/user_session.dart';
import 'package:sport_platform/modules/home/presentation/pages/home_page.dart';
import 'package:sport_platform/modules/users/domain/entities/user_profile_update.dart';
import 'package:sport_platform/modules/users/domain/repositories/i_user_profile_repository.dart';
import 'package:sport_platform/modules/users/presentation/widgets/complete_profile_body.dart';
import 'package:sport_platform/shared/widgets/app_snackbar.dart';
import 'package:sport_platform/shared/widgets/gradient_background.dart';

class CompleteProfilePage extends StatefulWidget {
  final bool editing;

  const CompleteProfilePage({super.key, this.editing = false});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final IUserProfileRepository _profileRepository =
      getIt<IUserProfileRepository>();
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _secondLastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = UserSession.current;
    _firstNameController.text = user?.firstName ?? '';
    _middleNameController.text = user?.middleName ?? '';
    _lastNameController.text = user?.lastName ?? '';
    _secondLastNameController.text = user?.secondLastName ?? '';
    _usernameController.text = user?.username ?? '';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _secondLastNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final updatedUser =
          await _profileRepository.updateProfile(_buildProfileUpdate());
      await UserSession.update(updatedUser);
      if (!mounted) return;
      if (widget.editing) {
        Navigator.of(context).pop(updatedUser);
        return;
      }
      AppSnackbar.success(context, ProfileStringsConstants.saveSuccess.tr());
      _navigateToHome();
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error(context, ProfileStringsConstants.saveError.tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  UserProfileUpdate _buildProfileUpdate() => UserProfileUpdate(
        firstName: _firstNameController.text.trim(),
        middleName: _optionalText(_middleNameController),
        lastName: _lastNameController.text.trim(),
        secondLastName: _optionalText(_secondLastNameController),
        username: _usernameController.text.trim(),
      );

  String? _optionalText(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  void _onSkip() {
    AppSnackbar.info(context, ProfileStringsConstants.skipInfo.tr());
    _navigateToHome();
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.editing
          ? AppBar(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
            )
          : null,
      body: GradientBackground(
        child: CompleteProfileBody(
          formKey: _formKey,
          firstNameController: _firstNameController,
          middleNameController: _middleNameController,
          lastNameController: _lastNameController,
          secondLastNameController: _secondLastNameController,
          usernameController: _usernameController,
          isLoading: _isLoading,
          onSubmit: _onSubmit,
          onSkip: widget.editing ? null : _onSkip,
          editing: widget.editing,
        ),
      ),
    );
  }
}
