import 'package:flutter/material.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/modules/auth/presentation/pages/register_page.dart';
import 'package:sport_platform/modules/auth/presentation/widgets/login_body.dart';
import 'package:sport_platform/shared/widgets/gradient_background.dart';
import 'package:sport_platform/core/network/api_endpoints.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  final _client = DioClient();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() async {
    try {
      if (!_formKey.currentState!.validate()) return;
      setState(() => _isLoading = true);
      _client.post(
            ApiEndpoints.login,
            data: {
              'email': _emailController.text,
              'password': _passwordController.text,
            },
          )
          .then((response) {
            // Handle successful login (e.g., save token, navigate to home)
            print('Login successful: ${response.data}');
            setState(() => _isLoading = false);
          })
          .catchError((error) {
            // Handle login error
            print('Login failed: $error');
            setState(() => _isLoading = false);
          });
    } catch (e) {
      print('Login error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        ),
      ),
    );
  }
}
