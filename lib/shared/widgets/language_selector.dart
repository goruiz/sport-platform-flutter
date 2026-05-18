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

    return Tooltip(
      message: 'settings.language_tooltip'.tr(),
      child: GestureDetector(
        onTap: () => _showLanguageSheet(context),
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
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    final currentCode = context.locale.languageCode;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primaryDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.inputBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'settings.select_language'.tr(),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ..._languages.map(
              (lang) => ListTile(
                leading: Text(lang.flag, style: const TextStyle(fontSize: 24)),
                title: Text(
                  lang.name,
                  style: const TextStyle(color: AppColors.white, fontSize: 15),
                ),
                subtitle: Text(
                  lang.code.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.whiteSubtle,
                    fontSize: 12,
                  ),
                ),
                trailing: currentCode == lang.code
                    ? const Icon(
                        Icons.check_circle,
                        color: AppColors.primaryLight,
                      )
                    : null,
                onTap: () {
                  context.setLocale(Locale(lang.code));
                  Navigator.pop(ctx);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
