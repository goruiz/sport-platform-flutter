import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/shared/widgets/app_viewport.dart';

Future<double> _childWidthIn(WidgetTester tester, Size windowSize) async {
  tester.view.physicalSize = windowSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    const Directionality(
      textDirection: TextDirection.ltr,
      child: AppViewport(child: SizedBox.expand(key: Key('content'))),
    ),
  );
  return tester.getSize(find.byKey(const Key('content'))).width;
}

void main() {
  testWidgets('en una pantalla ancha el contenido se limita al ancho máximo', (tester) async {
    expect(await _childWidthIn(tester, const Size(1400, 800)), lessThanOrEqualTo(AppSizes.maxContentWidth));
  });

  testWidgets('en un teléfono el contenido ocupa todo el ancho', (tester) async {
    expect(await _childWidthIn(tester, const Size(390, 844)), lessThanOrEqualTo(390));
    expect(await _childWidthIn(tester, const Size(390, 844)), greaterThan(380));
  });
}
