import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/services/locale_storage.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/shared/enums/app_language.dart';

/// Cambia el idioma de la app y lo guarda para que la próxima vez abra en él.
Future<void> applyAppLanguage(BuildContext context, AppLanguage language) async {
  await context.setLocale(language.locale);
  await LocaleStorage.save(language.locale);
}

/// El selector de idioma en forma de «píldora» con la bandera (para el login y el registro, donde aún no hay perfil).
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final current = AppLanguage.fromCode(context.locale.languageCode);

    return PopupMenuButton<AppLanguage>(
      tooltip: 'settings.language_tooltip'.tr(),
      onSelected: (language) => applyAppLanguage(context, language),
      itemBuilder: (_) => AppLanguage.values.map((language) {
        return PopupMenuItem<AppLanguage>(
          value: language,
          child: Row(
            children: [
              Text(language.flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  language.nativeName,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (current == language) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_circle, color: AppColors.primaryLight, size: 18),
              ],
            ],
          ),
        );
      }).toList(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            const SizedBox(width: 6),
            Text(
              current.code.toUpperCase(),
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.white, size: 18),
          ],
        ),
      ),
    );
  }
}
