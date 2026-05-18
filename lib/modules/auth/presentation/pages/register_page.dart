import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/strings_constants/auth_strings_constants/register_strings_constants.dart';
import 'package:sport_platform/modules/auth/presentation/widgets/register_body.dart';
import 'package:sport_platform/modules/users/presentation/pages/complete_profile_page.dart';
import 'package:sport_platform/shared/widgets/gradient_background.dart';
import 'package:sport_platform/shared/widgets/app_snackbar.dart';
import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showPassword = true;
  bool _showConfirmPassword = true;
  bool _isLoading = false;
  final _client = DioClient();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _client.post(
        ApiEndpoints.register,
        data: {
          'email': _emailController.text,
          'password': _passwordController.text,
          'confirm_password': _confirmPasswordController.text,
        },
      );
      if (!mounted) return;
      AppSnackbar.success(context, RegisterStringsConstants.successMessage.tr());
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CompleteProfilePage()),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, RegisterStringsConstants.errorMessage.tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: RegisterBody(
          formKey: _formKey,
          emailController: _emailController,
          passwordController: _passwordController,
          confirmPasswordController: _confirmPasswordController,
          showPassword: _showPassword,
          showConfirmPassword: _showConfirmPassword,
          isLoading: _isLoading,
          onRegister: _onRegister,
          onTogglePassword: () =>
              setState(() => _showPassword = !_showPassword),
          onToggleConfirmPassword: () =>
              setState(() => _showConfirmPassword = !_showConfirmPassword),
          onSignIn: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
