import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `LocaleKeys` (`lib/core/constants/locale_keys.g.dart`) es la lista de las claves de traducción para que un error de
/// tipeo falle al compilar y no se vea como una clave cruda en pantalla. Se genera del diccionario en español:
///
///     dart run easy_localization:generate -S assets/translations -O lib/core/constants -o locale_keys.g.dart -f keys
///
/// Estas pruebas avisan si se agregó una clave al JSON sin volver a generarla, o si alguien escribió una clave a mano.
void main() {
  final dictionary = jsonDecode(File('assets/translations/es.json').readAsStringSync()) as Map<String, dynamic>;
  final leaves = <String>{};
  final groups = <String>{};
  _collectKeys(dictionary, '', leaves, groups);

  final generated = _readGeneratedKeys();

  test('LocaleKeys tiene una constante por cada clave del diccionario', () {
    expect(leaves.difference(generated), isEmpty, reason: 'faltan en LocaleKeys: vuelve a generarla con el comando de arriba');
  });

  test('LocaleKeys no conserva claves que ya no están en el diccionario', () {
    expect(generated.difference({...leaves, ...groups}), isEmpty, reason: 'sobran en LocaleKeys: vuelve a generarla');
  });

  test('ningún texto del código repite una clave a mano: se usa su constante de LocaleKeys', () {
    final offenders = _handWrittenKeys(leaves);

    expect(offenders, isEmpty, reason: 'Usa LocaleKeys.<clave> en vez del texto:\n${offenders.map((o) => '  $o').join('\n')}');
  });
}

void _collectKeys(Map<String, dynamic> node, String prefix, Set<String> leaves, Set<String> groups) {
  for (final entry in node.entries) {
    final path = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    if (entry.value is Map<String, dynamic>) {
      groups.add(path);
      _collectKeys(entry.value as Map<String, dynamic>, path, leaves, groups);
    } else {
      leaves.add(path);
    }
  }
}

Set<String> _readGeneratedKeys() {
  final source = File('lib/core/constants/locale_keys.g.dart').readAsStringSync();
  return RegExp(r"static const \w+ = '([^']*)';").allMatches(source).map((match) => match.group(1)!).toSet();
}

/// Los textos entre comillas de `lib/` que son exactamente una clave del diccionario, fuera del archivo generado y de los
/// comentarios.
List<String> _handWrittenKeys(Set<String> keys) {
  final literal = RegExp(r"""(?<![\w$.])'([A-Za-z0-9_]+(?:\.[A-Za-z0-9_]+)+)'(?![\w$])""");
  final offenders = <String>[];

  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart') || entity.path.endsWith('locale_keys.g.dart')) continue;
    final lines = entity.readAsLinesSync();
    for (var index = 0; index < lines.length; index++) {
      if (lines[index].trimLeft().startsWith('//')) continue;
      for (final match in literal.allMatches(lines[index])) {
        if (keys.contains(match.group(1))) {
          offenders.add('${entity.path.replaceAll('\\', '/')}:${index + 1}  ${match.group(0)}');
        }
      }
    }
  }
  return offenders;
}
