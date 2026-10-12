import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_platform/core/services/auth_storage.dart';
import 'package:sport_platform/core/services/session_service.dart';
import 'package:sport_platform/shared/services/session_expired_handler.dart';

void main() {
  const homeText = 'home page';
  const loginText = 'login page';

  late GlobalKey<NavigatorState> navigatorKey;
  late int stateResets;
  late SessionExpiredHandler handler;

  // Sin EasyLocalization montado el aviso usa la clave tal cual; se silencia el log de clave faltante.
  setUpAll(() => EasyLocalization.logger.enableBuildModes = []);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    navigatorKey = GlobalKey<NavigatorState>();
    stateResets = 0;
    handler = SessionExpiredHandler(
      sessionService: SessionService(resetSessionScopedState: () => stateResets++),
      navigatorKey: navigatorKey,
      loginPageBuilder: () => const Scaffold(body: Text(loginText)),
    );
  });

  Future<void> pumpApp(WidgetTester tester) => tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: Text(homeText)),
        ),
      );

  testWidgets('cierra la sesión y lleva al login avisando al usuario', (tester) async {
    await AuthStorage.saveToken('token');
    await pumpApp(tester);

    await handler.onSessionExpired();
    await tester.pumpAndSettle();

    expect(find.text(loginText), findsOneWidget);
    expect(find.text(homeText), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(await AuthStorage.hasToken(), isFalse);
  });

  testWidgets('con varios 401 simultáneos cierra la sesión una sola vez', (tester) async {
    await AuthStorage.saveToken('token');
    await pumpApp(tester);

    await Future.wait([
      handler.onSessionExpired(),
      handler.onSessionExpired(),
      handler.onSessionExpired(),
    ]);
    await tester.pumpAndSettle();

    expect(stateResets, 1);
    expect(find.text(loginText), findsOneWidget);
  });

  testWidgets('no hace nada si la sesión ya estaba cerrada', (tester) async {
    await pumpApp(tester);

    await handler.onSessionExpired();
    await tester.pumpAndSettle();

    expect(find.text(homeText), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(stateResets, 0);
  });
}
