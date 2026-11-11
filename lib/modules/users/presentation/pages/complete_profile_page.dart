import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/strings_constants/profile_strings_constants.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/services/user_session.dart';
import 'package:sport_platform/modules/home/presentation/pages/home_page.dart';
import 'package:sport_platform/modules/users/domain/enums/gender.dart';
import 'package:sport_platform/modules/users/domain/name_rules.dart';
import 'package:sport_platform/modules/users/domain/entities/user_entity.dart';
import 'package:sport_platform/modules/users/domain/entities/user_profile_update.dart';
import 'package:sport_platform/modules/users/domain/profile_field_errors.dart';
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
  Gender? _gender;
  DateTime? _birthDate;
  ProfileFieldErrors _fieldErrors = ProfileFieldErrors.none;
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
    _gender = user?.gender;
    _birthDate = user?.birthDate;
    if (widget.editing) _fillMissingPersonalData();
  }

  /// El token con que se inició la sesión no trae el género ni la fecha de nacimiento: al editar se leen de la cuenta, y
  /// solo se rellenan los que aún no tienen valor (lo que la persona ya eligió mientras tanto no se pisa). Si la lectura
  /// falla, el formulario queda vacío en esos dos campos y se completan a mano.
  Future<void> _fillMissingPersonalData() async {
    if (_gender != null && _birthDate != null) return;
    final UserEntity account;
    try {
      account = await _profileRepository.getCurrentAccount();
    } catch (_) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _gender ??= account.gender;
      _birthDate ??= account.birthDate;
    });
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
    } catch (error) {
      if (!mounted) return;
      _showSaveFailure(error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Un género o una fecha que el backend rechazó se explica bajo su campo; cualquier otro fallo, con el aviso general.
  void _showSaveFailure(Object error) {
    final fieldErrors = ProfileFieldErrors.fromException(error);
    if (fieldErrors.isEmpty) {
      AppSnackbar.error(context, ProfileStringsConstants.saveError.tr());
      return;
    }
    setState(() => _fieldErrors = fieldErrors);
  }

  UserProfileUpdate _buildProfileUpdate() => UserProfileUpdate(
        firstName: normalizePersonName(_firstNameController.text),
        middleName: _optionalText(_middleNameController),
        lastName: normalizePersonName(_lastNameController.text),
        secondLastName: _optionalText(_secondLastNameController),
        username: _usernameController.text.trim(),
        gender: _gender,
        birthDate: _birthDate,
      );

  String? _optionalText(TextEditingController controller) {
    final text = normalizePersonName(controller.text);
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
          gender: _gender,
          onGenderChanged: (gender) => setState(() {
            _gender = gender;
            _fieldErrors = ProfileFieldErrors(birthDate: _fieldErrors.birthDate);
          }),
          birthDate: _birthDate,
          onBirthDateChanged: (date) => setState(() {
            _birthDate = date;
            _fieldErrors = ProfileFieldErrors(gender: _fieldErrors.gender);
          }),
          genderServerError: _fieldErrors.gender?.translationKey.tr(),
          birthDateServerError: _fieldErrors.birthDate?.translationKey.tr(),
          isLoading: _isLoading,
          onSubmit: _onSubmit,
          onSkip: widget.editing ? null : _onSkip,
          editing: widget.editing,
        ),
      ),
    );
  }
}
