import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/strings_constants/app_strings_constants.dart';
import 'package:sport_platform/core/theme/app_colors.dart';

class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key});

  @override
  Widget build(BuildContext context) {
    context.locale; // register as dependent so it rebuilds on locale change
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
        Text(
          AppStringsConstants.appName.tr(),
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppStringsConstants.appTagline.tr(),
          style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 13),
        ),
      ],
    );
  }
}
