import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/real_translations.dart';

// Los textos de la pantalla de complejos, la insignia del capitán y la opción de menú que manda el backend al rol
// «Usuario». Si falta uno en un idioma, la app enseñaría la clave cruda.
const _keys = <String>[
  'menu.admin.sport_complexes',
  'menu.admin.sport_complexes_description',
  'mobile.teams.captain',
  'mobile.complexes.load_error',
  'mobile.complexes.empty_title',
  'mobile.complexes.empty_subtitle',
  'mobile.complexes.search_hint',
  'mobile.complexes.filtered_empty_title',
  'mobile.complexes.filtered_empty_subtitle',
  'mobile.complexes.courts_count',
  'mobile.complexes.no_location',
  'mobile.complexes.location_title',
  'mobile.complexes.no_location_detail',
  'mobile.complexes.courts_title',
  'mobile.complexes.no_courts',
];

void main() {
  setUpAll(initRealTranslations);

  for (final locale in supportedTestLocales) {
    testWidgets('los textos de complejos y capitán se resuelven en ${locale.languageCode}', (tester) async {
      var unresolved = <String>[];
      String? courtsCount;

      await pumpWithRealTranslations(
        tester,
        locale: locale,
        home: (_) {
          unresolved = [for (final key in _keys) if (key.tr() == key) key];
          courtsCount = 'mobile.complexes.courts_count'.tr(namedArgs: {'count': '3'});
          return const SizedBox.shrink();
        },
      );

      expect(unresolved, isEmpty, reason: 'sin traducción en ${locale.languageCode}');
      expect(courtsCount, contains('3'), reason: 'el contador de canchas no se rellena en ${locale.languageCode}');
    });
  }
}
