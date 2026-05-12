import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/main.dart';

void main() {
  testWidgets('LoginPage renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const SportsPlatform());

    expect(find.text('Sportify'), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
