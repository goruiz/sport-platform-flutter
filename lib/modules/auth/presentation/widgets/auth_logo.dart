import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/auth_constants/login_strings_constants.dart';
import 'package:sport_platform/core/theme/app_colors.dart';

class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryLight,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryLight.withValues(alpha: 0.5),
                blurRadius: 40,
                spreadRadius: 8,
              ),
            ],
          ),
          child: const Icon(
            Icons.sports_soccer,
            size: 50,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          LoginStringsConstants.appName,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          LoginStringsConstants.appTagline,
          style: TextStyle(color: AppColors.whiteSubtle, fontSize: 13),
        ),
      ],
    );
  }
}
