import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/app_constants.dart';
import 'package:sport_platform/core/constants/strings_constants/auth_strings_constants/login_strings_constants.dart';
import 'package:sport_platform/modules/auth/data/datasource/login_service.dart';
import 'package:sport_platform/modules/auth/presentation/pages/register_page.dart';
import 'package:sport_platform/modules/auth/presentation/pages/password_recovery_page.dart';
import 'package:sport_platform/modules/auth/presentation/widgets/login_body.dart';
import 'package:sport_platform/modules/home/presentation/pages/home_page.dart';
import 'package:sport_platform/shared/widgets/app_snackbar.dart';
import 'package:sport_platform/shared/widgets/gradient_background.dart';
import 'package:sport_platform/shared/widgets/language_selector.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(
    text: AppConstants.fixedLoginEmail,
  );
  final _passwordController = TextEditingController(
    text: AppConstants.fixedLoginPassword,
  );
  bool _obscurePassword = true;
  bool _isLoading = false;
  final _loginService = LoginService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _loginService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, LoginStringsConstants.invalidCredentials.tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [LanguageSelector(), SizedBox(width: 8)],
      ),
      body: GradientBackground(
        child: LoginBody(
          formKey: _formKey,
          emailController: _emailController,
          passwordController: _passwordController,
          obscurePassword: _obscurePassword,
          isLoading: _isLoading,
          onLogin: _onLogin,
          onTogglePassword: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          onSignUp: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const RegisterPage())),
          onForgotPassword: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ForgotPasswordPage())),
        ),
      ),
    );
  }
}
