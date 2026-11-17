import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';

/// Un espacio, una esquina o un estilo de texto que ya tiene su token (`core/theme`) se pide por su nombre, no escribiendo
/// el número: así cambiar el diseño es cambiar un solo valor. Solo se vigilan los números que coinciden con un token; los
/// que no (un 14 o un 36 sueltos) son medidas propias de un widget.
void main() {
  final spacingValues = _valuesOf([
    AppSpacing.hairline, AppSpacing.xs, AppSpacing.tight, AppSpacing.sm, AppSpacing.snug, AppSpacing.md, AppSpacing.lg,
    AppSpacing.xl, AppSpacing.xxl, AppSpacing.section, AppSpacing.xxxl,
  ]);
  final radiusValues = _valuesOf([AppRadius.sm, AppRadius.compact, AppRadius.md, AppRadius.lg]);

  test('los espacios entre elementos salen de AppSpacing', () {
    final offenders = _findInLib(
      RegExp(r'SizedBox\(\s*(?:height|width):\s*(\d+)\s*\)'),
      isOffender: (match) => spacingValues.contains(match.group(1)),
    );

    expect(offenders, isEmpty, reason: _explain('Usa SizedBox(height: AppSpacing.<token>)', offenders));
  });

  test('los rellenos (EdgeInsets) salen de AppSpacing cuando su valor tiene token', () {
    final numberInside = RegExp(r'(?<![\w.])(\d+)(?![\w.])');
    final offenders = _findInLib(
      RegExp(r'EdgeInsets\.(?:all|symmetric|only|fromLTRB)\(([^()]*)\)'),
      isOffender: (match) => numberInside.allMatches(match.group(1)!).any((number) => spacingValues.contains(number.group(1))),
    );

    expect(offenders, isEmpty, reason: _explain('Usa AppSpacing.<token> en cada medida que tenga uno', offenders));
  });

  test('las esquinas redondeadas salen de AppRadius', () {
    final offenders = _findInLib(
      RegExp(r'(?:Border)?Radius\.circular\(\s*(\d+)\s*\)'),
      isOffender: (match) => radiusValues.contains(match.group(1)),
    );

    expect(offenders, isEmpty, reason: _explain('Usa BorderRadius.circular(AppRadius.<token>)', offenders));
  });

  test('un texto que es exactamente un estilo de AppTextStyles lo usa', () {
    // Cada estilo de AppTextStyles que es solo un color y un tamaño: «color:tamaño».
    const stylesByColorAndSize = {
      'white:14', 'whiteSubtle:14', 'white:15', 'whiteSubtle:13', 'whiteSubtle:12', 'whiteSubtle:11', 'whiteSubtle:12.5',
    };
    final offenders = _findInLib(
      RegExp(r'TextStyle\(\s*color:\s*AppColors\.(white|whiteSubtle),\s*fontSize:\s*(\d+(?:\.\d+)?),?\s*\)'),
      isOffender: (match) => stylesByColorAndSize.contains('${match.group(1)}:${match.group(2)}'),
    );

    expect(offenders, isEmpty, reason: _explain('Usa AppTextStyles.body, bodyMuted, bodyLarge, secondary, footnote, micro o caption', offenders));
    // Que los estilos existan con el tamaño que dicen.
    expect(AppTextStyles.footnote.fontSize, 12);
    expect(AppTextStyles.secondary.fontSize, 13);
  });
}

/// Los valores como los escribe el código: `8` y no `8.0`.
Set<String> _valuesOf(List<num> values) => {
      for (final value in values) value == value.roundToDouble() ? value.toInt().toString() : value.toString(),
    };

/// Los lugares de `lib/` (fuera de `core/theme`, donde se definen los tokens) que coinciden con [pattern] y [isOffender].
List<String> _findInLib(RegExp pattern, {required bool Function(RegExpMatch match) isOffender}) {
  final offenders = <String>[];
  for (final entity in Directory('lib').listSync(recursive: true)) {
    final path = entity.path.replaceAll('\\', '/');
    if (entity is! File || !path.endsWith('.dart') || path.startsWith('lib/core/theme/')) continue;
    final source = entity.readAsStringSync();
    for (final match in pattern.allMatches(source)) {
      if (!isOffender(match)) continue;
      final line = '\n'.allMatches(source.substring(0, match.start)).length + 1;
      offenders.add('$path:$line  ${match.group(0)!.replaceAll(RegExp(r'\s+'), ' ')}');
    }
  }
  return offenders;
}

String _explain(String rule, List<String> offenders) => '$rule. Lo incumplen:\n${offenders.map((o) => '  $o').join('\n')}';
