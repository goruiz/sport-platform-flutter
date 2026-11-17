import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/core/constants/locale_keys.g.dart';
import 'package:sport_platform/core/services/user_session.dart';
import 'package:sport_platform/core/theme/app_colors.dart';

class GreetingBanner extends StatelessWidget {
  const GreetingBanner({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return LocaleKeys.home_greeting_morning.tr();
    if (h < 18) return LocaleKeys.home_greeting_afternoon.tr();
    return LocaleKeys.home_greeting_evening.tr();
  }

  @override
  Widget build(BuildContext context) {
    final user = UserSession.current;
    final name = user == null || user.fullName.isEmpty
        ? LocaleKeys.home_guest_name.tr()
        : user.fullName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.primaryLight,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: AppTextStyles.secondary,
              ),
              const SizedBox(height: AppSpacing.hairline),
              Text(
                name,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
