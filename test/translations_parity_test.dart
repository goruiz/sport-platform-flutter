import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Los cuatro diccionarios tienen exactamente las mismas claves: una que falte en un idioma se vería como la clave cruda.
Set<String> _keysOf(Object? node, [String prefix = '']) {
  if (node is Map<String, dynamic>) {
    return {
      for (final entry in node.entries) ..._keysOf(entry.value, prefix.isEmpty ? entry.key : '$prefix.${entry.key}'),
    };
  }
  return {prefix};
}

void main() {
  const languages = ['es', 'en', 'fr', 'de'];

  final keysByLanguage = {
    for (final language in languages)
      language: _keysOf(jsonDecode(File('assets/translations/$language.json').readAsStringSync())),
  };

  for (final language in languages.skip(1)) {
    test('$language tiene las mismas claves que es', () {
      final spanish = keysByLanguage['es']!;
      final other = keysByLanguage[language]!;

      expect(spanish.difference(other), isEmpty, reason: 'faltan en $language');
      expect(other.difference(spanish), isEmpty, reason: 'sobran en $language');
    });
  }

  test('las claves de las pantallas nuevas existen', () {
    const needed = [
      'account.change_password.title',
      'account.delete.warning',
      'account.errors.INCORRECT_PASSWORD',
      'verify_email.title',
      'join_team.errors.JOIN_CODE_NOT_FOUND',
      'join_team.errors.EMAIL_NOT_VERIFIED',
      'invitations.errors.EMAIL_NOT_VERIFIED',
      'mobile.events.search_hint',
      'mobile.matches.pick_event',
      'match_detail.share_result',
      'rankings.my_stats.title',
      'common.cancel',
    ];

    for (final key in needed) {
      expect(keysByLanguage['es'], contains(key), reason: key);
    }
  });
}
