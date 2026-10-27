import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const supportedTestLocales = [Locale('es'), Locale('en'), Locale('fr'), Locale('de')];

/// Prepara EasyLocalization como lo hace `main()`. Va en el `setUpAll` de cada archivo que use [pumpWithRealTranslations].
Future<void> initRealTranslations() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  EasyLocalization.logger.enableBuildModes = [];
  await EasyLocalization.ensureInitialized();
}

/// Pinta [home] con los diccionarios reales de `assets/translations`, cargados como los carga la app (EasyLocalization
/// y los delegados de un MaterialApp).
///
/// Mientras se cargan, `tr()` responde la propia clave y EasyLocalization no construye nada. Leer los assets es E/S
/// real, que el reloj simulado de los tests no espera, así que se espera fuera de él hasta que [home] se construye; si
/// no llega a construirse, la prueba falla en vez de pasar en vacío.
Future<void> pumpWithRealTranslations(
  WidgetTester tester, {
  required Widget Function(BuildContext context) home,
  Locale locale = const Locale('es'),
}) async {
  var hasBuilt = false;

  await tester.runAsync(() async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: supportedTestLocales,
        path: 'assets/translations',
        fallbackLocale: const Locale('es'),
        startLocale: locale,
        child: Builder(
          builder: (easyContext) => MaterialApp(
            localizationsDelegates: easyContext.localizationDelegates,
            supportedLocales: easyContext.supportedLocales,
            locale: easyContext.locale,
            home: Builder(
              builder: (context) {
                hasBuilt = true;
                return home(context);
              },
            ),
          ),
        ),
      ),
    );

    for (var attempt = 0; attempt < 50 && !hasBuilt; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump();
    }
    // Un último cuadro: `home` se vuelve a construir con los diccionarios ya cargados.
    await tester.pump();
  });

  expect(hasBuilt, isTrue, reason: 'EasyLocalization no llegó a construir: los diccionarios no se cargaron');
}
