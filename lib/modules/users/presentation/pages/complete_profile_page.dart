import 'package:flutter/material.dart';
import 'package:sport_platform/modules/home/presentation/pages/home_page.dart';
import 'package:sport_platform/modules/users/presentation/widgets/complete_profile_body.dart';
import 'package:sport_platform/shared/widgets/app_snackbar.dart';
import 'package:sport_platform/shared/widgets/gradient_background.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _secondLastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _secondLastNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // TODO: llamar al endpoint de actualización de perfil
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      AppSnackbar.success(context, 'Perfil completado exitosamente');
      _navigateToHome();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Error al guardar el perfil. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSkip() {
    AppSnackbar.info(context, 'Puedes completar tu perfil más tarde desde ajustes.');
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
          onSkip: _onSkip,
        ),
      ),
    );
  }
}
