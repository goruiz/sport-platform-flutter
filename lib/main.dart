import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/app_constants.dart';
import 'package:sport_platform/core/theme/app_theme.dart';
import 'package:sport_platform/modules/auth/presentation/pages/login_page.dart';

void main() {
  runApp(const SportsPlatform());
}

class SportsPlatform extends StatelessWidget {
  const SportsPlatform({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.sportsPlatform,
      home: const LoginPage(),
    );
  }
}
