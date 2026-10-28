import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';

import '../../support/real_translations.dart';

// Las claves que el backend manda en `GET /menu/for-current-user` al rol «Usuario» (nombre y descripción de cada
// opción, sembradas por las migraciones). Si una falta en un idioma, la app enseñaría el texto de la base o la clave.
const _menuKeys = <String>[
  // Grupos
  'menu.admin.group_competition',
  'menu.admin.group_competition_description',
  'menu.admin.group_results',
  'menu.admin.group_results_description',
  'menu.admin.group_teams',
  'menu.admin.group_teams_description',
  'menu.admin.group_facilities',
  'menu.admin.group_facilities_description',
  'menu.admin.group_mobile_app',
  'menu.admin.group_mobile_app_description',
  // Opciones
  'menu.home',
  'menu.home_description',
  'menu.leagues.title',
  'menu.leagues.description',
  'home.action_my_matches',
  'menu.matches_description',
  'menu.rankings',
  'menu.rankings_description',
  'menu.reports',
  'menu.reports_description',
  'menu.profile',
  'menu.profile_description',
  'menu.admin.events',
  'menu.admin.events_description',
  'menu.admin.teams',
  'menu.admin.teams_description',
  'menu.courts',
  'menu.admin.courts_description',
];

void main() {
  setUpAll(initRealTranslations);

  for (final locale in supportedTestLocales) {
    testWidgets(
      'las claves del menú que manda el backend se resuelven en ${locale.languageCode}',
      (WidgetTester tester) async {
        var unresolved = <String>[];

        await pumpWithRealTranslations(
          tester,
          locale: locale,
          // Cada construcción reemplaza la anterior: solo cuenta la última, con los diccionarios ya cargados.
          home: (_) {
            unresolved = [for (final key in _menuKeys) if (key.tr() == key) key];
            return const SizedBox.shrink();
          },
        );

        expect(unresolved, isEmpty, reason: 'sin traducción en ${locale.languageCode}');
      },
    );
  }

  testWidgets('un grupo del menú se lee con su nombre y su descripción, no con la clave ni con el texto de la base',
      (WidgetTester tester) async {
    String? groupName;
    String? groupDescription;

    await pumpWithRealTranslations(
      tester,
      home: (_) {
        final group = MenuItemModel.fromJson({
          'id': '1',
          'name': 'Texto de la base',
          'translationKey': 'menu.admin.group_results',
          'description': 'Descripción de la base',
          'descriptionTranslationKey': 'menu.admin.group_results_description',
        });
        groupName = group.localizedName;
        groupDescription = group.localizedDescription;
        return const SizedBox.shrink();
      },
    );

    expect(groupName, 'Resultados y estadísticas');
    expect(groupDescription, 'Ligas, partidos, rankings y reportes');
  });
}
