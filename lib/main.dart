import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/strings_constants/app_strings_constants.dart';
import 'package:sport_platform/core/theme/app_theme.dart';
import 'package:sport_platform/modules/auth/presentation/pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
        Locale('fr'),
        Locale('de'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('es'),
      startLocale: const Locale('es'),
      child: const SportsPlatform(),
    ),
  );
}

class SportsPlatform extends StatelessWidget {
  const SportsPlatform({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.sportsPlatform,
      onGenerateTitle: (ctx) => AppStringsConstants.appName.tr(),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: const LoginPage(),
    );
  }
}
