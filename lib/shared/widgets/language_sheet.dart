import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/shared/enums/app_language.dart';
import 'package:sport_platform/shared/widgets/language_selector.dart';
import 'package:sport_platform/shared/widgets/sheet_handle.dart';

/// Abre una hoja inferior con los idiomas disponibles; al elegir uno la app cambia y la hoja se cierra.
Future<void> showLanguageSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => const _LanguageSheet(),
  );
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context) {
    final current = AppLanguage.fromCode(context.locale.languageCode);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, AppSpacing.md, 0, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.sm),
              child: Text('settings.select_language'.tr(), style: AppTextStyles.sectionTitle),
            ),
            for (final language in AppLanguage.values)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                leading: Text(language.flag, style: const TextStyle(fontSize: 26)),
                title: Text(language.nativeName, style: AppTextStyles.body.copyWith(fontSize: 16)),
                trailing: current == language
                    ? const Icon(Icons.check_circle, color: AppColors.primaryLight)
                    : null,
                onTap: () async {
                  // Primero se cambia el idioma (hace falta el contexto vivo) y después se cierra la hoja.
                  await applyAppLanguage(context, language);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}
