import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_platform/core/constants/strings_constants/auth_strings_constants/login_strings_constants.dart';
import 'package:sport_platform/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // EasyLocalization lee SharedPreferences al inicializarse: los valores simulados van antes.
    SharedPreferences.setMockInitialValues({});
    EasyLocalization.logger.enableBuildModes = [];
    await EasyLocalization.ensureInitialized();
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows the login page when there is no saved session',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('es')],
        path: 'assets/translations',
        fallbackLocale: const Locale('es'),
        startLocale: const Locale('es'),
        child: const SportsPlatform(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(LoginStringsConstants.welcomeBack.tr()), findsOneWidget);
    expect(find.text(LoginStringsConstants.signIn.tr()), findsOneWidget);
  });
}
