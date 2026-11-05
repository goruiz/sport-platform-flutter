import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/home/presentation/widgets/quick_actions_carousel.dart';

import '../../support/real_translations.dart';

// Los grupos que el rol «Usuario» recibe en `GET /menu/for-current-user` y que el menú de inicio pinta como tarjetas
// (los de la barra inferior ya se quitaron), tal como llegan: con el nombre de la base y la clave de traducción.
List<MenuItemModel> _groupsOfTheUserRole() => [
      MenuItemModel.fromJson({
        'id': 'g1',
        'name': 'Resultados y estadísticas',
        'translationKey': 'menu.admin.group_results',
        'icon': 'cilChart',
        'order': 2,
        'submenus': [
          {'id': 'i1', 'name': 'Partidos', 'url': '/matches', 'translationKey': 'home.action_my_matches', 'order': 1},
        ],
      }),
      MenuItemModel.fromJson({
        'id': 'g2',
        'name': 'Instalaciones',
        'translationKey': 'menu.admin.group_facilities',
        'icon': 'cilHouse',
        'order': 4,
        'submenus': [
          {'id': 'i2', 'name': 'Canchas', 'url': '/courts', 'translationKey': 'menu.courts', 'order': 1},
        ],
      }),
    ];

Widget _carousel(List<MenuItemModel> items) => Scaffold(
      body: QuickActionsCarousel(items: items, isLoading: false, hasError: false, onRetry: () {}),
    );

void main() {
  setUpAll(initRealTranslations);

  testWidgets('las tarjetas de grupo se leen con el nombre en el idioma de la app, nunca con la clave', (tester) async {
    await pumpWithRealTranslations(tester, home: (_) => _carousel(_groupsOfTheUserRole()));

    expect(find.text('Resultados y estadísticas'), findsOneWidget);
    expect(find.text('Instalaciones'), findsOneWidget);

    expect(find.text('menu.admin.group_results'), findsNothing);
    expect(find.text('menu.admin.group_facilities'), findsNothing);
  });

  testWidgets('una clave que el diccionario no conoce enseña el nombre de la base y no la clave', (tester) async {
    final item = MenuItemModel.fromJson({
      'id': 'g9',
      'name': 'Grupo nuevo',
      'translationKey': 'menu.admin.group_que_no_existe',
      'submenus': [
        {'id': 'i9', 'name': 'Opción', 'url': '/x', 'order': 1},
      ],
    });

    await pumpWithRealTranslations(tester, home: (_) => _carousel([item]));

    expect(find.text('Grupo nuevo'), findsOneWidget);
    expect(find.text('menu.admin.group_que_no_existe'), findsNothing);
  });

  testWidgets('en inglés las tarjetas se leen en inglés', (tester) async {
    await pumpWithRealTranslations(tester, locale: const Locale('en'), home: (_) => _carousel(_groupsOfTheUserRole()));

    expect(find.text('Results and statistics'), findsOneWidget);
    expect(find.text('Facilities'), findsOneWidget);
  });
}
