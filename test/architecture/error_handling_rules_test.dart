import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Un error que la app atrapa tiene que dejar rastro: o se usa su causa (se traduce a un mensaje, se relanza) o se
/// registra con `AppLogger`. Sin esto una pantalla que falla se queda en blanco y nadie sabe por qué. Las dos formas de
/// perder la causa son `catch (_)` y un `catch` con el cuerpo vacío.
void main() {
  final catches = _readCatches();

  test('ningún catch descarta la causa del error (catch (_))', () {
    final offenders = catches.where((c) => c.discardsCause);

    expect(offenders, isEmpty, reason: _explain('Usa `catch (error, stackTrace)` y registra con AppLogger', offenders));
  });

  test('ningún catch tiene el cuerpo vacío', () {
    final offenders = catches.where((c) => c.isEmpty);

    expect(offenders, isEmpty, reason: _explain('Un catch vacío esconde el fallo: registra con AppLogger.warning si es a propósito', offenders));
  });
}

class _Catch {
  final String file;
  final int line;
  final bool discardsCause;
  final bool isEmpty;

  const _Catch(this.file, this.line, {required this.discardsCause, required this.isEmpty});

  @override
  String toString() => '$file:$line';
}

/// Todos los `catch` de `lib/` (sin contar los comentarios) con lo que hacen con la causa.
List<_Catch> _readCatches() {
  final catchClause = RegExp(r'catch\s*\(\s*(\w+)(?:\s*,\s*\w+)?\s*\)\s*\{(\s*)\}?');
  final catches = <_Catch>[];

  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final lines = entity.readAsLinesSync();
    final code = lines.map((line) => line.trimLeft().startsWith('//') ? '' : line).join('\n');

    for (final match in catchClause.allMatches(code)) {
      final line = '\n'.allMatches(code.substring(0, match.start)).length + 1;
      final closesRightAway = match.group(0)!.trimRight().endsWith('}');
      catches.add(_Catch(
        entity.path.replaceAll('\\', '/'),
        line,
        discardsCause: match.group(1) == '_',
        isEmpty: closesRightAway,
      ));
    }
  }
  return catches;
}

String _explain(String rule, Iterable<_Catch> offenders) => '$rule. Catch que lo incumplen:\n${offenders.map((c) => '  $c').join('\n')}';
