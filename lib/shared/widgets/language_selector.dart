import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  static const _languages = [
    (name: 'Español', code: 'es', flag: '🇪🇸'),
    (name: 'English', code: 'en', flag: '🇬🇧'),
    (name: 'Français', code: 'fr', flag: '🇫🇷'),
    (name: 'Deutsch', code: 'de', flag: '🇩🇪'),
  ];

  @override
  Widget build(BuildContext context) {
    final currentCode = context.locale.languageCode;
    final current = _languages.firstWhere(
      (l) => l.code == currentCode,
      orElse: () => _languages.first,
    );

    return PopupMenuButton<String>(
      tooltip: 'settings.language_tooltip'.tr(),
      onSelected: (code) => context.setLocale(Locale(code)),
      color: AppColors.primaryDark,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.inputBorder),
      ),
      itemBuilder: (_) => _languages.map((lang) {
        return PopupMenuItem<String>(
          value: lang.code,
          child: Row(
            children: [
              Text(lang.flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      lang.name,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      lang.code.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.whiteSubtle,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (currentCode == lang.code) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_circle, color: AppColors.primaryLight, size: 18),
              ],
            ],
          ),
        );
      }).toList(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(current.flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 5),
            Text(
              currentCode.toUpperCase(),
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
