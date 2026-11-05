import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/home/presentation/widgets/quick_actions_grid.dart';

import '../../support/real_translations.dart';

MenuItemModel _leaf(String id, String name, {String? translationKey, int order = 0}) => MenuItemModel.fromJson({
      'id': id,
      'name': name,
      'url': '/$id',
      'translationKey': translationKey,
      'order': order,
    });

// Los grupos que el rol «Usuario» recibe en `GET /menu/for-current-user` y que el menú de inicio pinta (los de la
// barra inferior ya se quitaron), tal como llegan: con el nombre de la base y la clave de traducción.
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

Widget _grid(List<MenuItemModel> items) => Scaffold(
      body: SingleChildScrollView(
        child: QuickActionsGrid(items: items, isLoading: false, hasError: false, onRetry: () {}),
      ),
    );

void main() {
  setUpAll(initRealTranslations);

  group('buildSections', () {
    test('las opciones sueltas seguidas forman un bloque sin título', () {
      final sections = QuickActionsGrid.buildSections([_leaf('a', 'A'), _leaf('b', 'B')]);

      expect(sections, hasLength(1));
      expect(sections.single.title, isNull);
      expect(sections.single.items.map((item) => item.id), ['a', 'b']);
    });

    test('cada grupo forma su bloque con su nombre y respeta el orden del menú', () {
      final sections = QuickActionsGrid.buildSections([
        _leaf('a', 'A'),
        _groupsOfTheUserRole().first,
        _leaf('b', 'B'),
      ]);

      expect(sections.map((section) => section.title), [null, 'Resultados y estadísticas', null]);
      expect(sections[1].items.map((item) => item.id), ['i1']);
    });

    test('sin opciones no hay bloques', () {
      expect(QuickActionsGrid.buildSections(const []), isEmpty);
    });
  });

  group('columnsFor', () {
    // El ancho útil de un teléfono de 390 px con su margen de 16 a cada lado.
    const phoneWidth = 358.0;

    test('un acceso solo ocupa toda la fila', () {
      expect(QuickActionsGrid.columnsFor(1, phoneWidth), 1);
    });

    test('dos accesos se reparten la fila en vez de quedarse a un lado', () {
      expect(QuickActionsGrid.columnsFor(2, phoneWidth), 2);
    });

    test('en un teléfono caben tres por fila', () {
      expect(QuickActionsGrid.columnsFor(3, phoneWidth), 3);
      expect(QuickActionsGrid.columnsFor(6, phoneWidth), 3);
    });

    test('cuatro accesos forman dos filas de dos, no una de tres y una suelta', () {
      expect(QuickActionsGrid.columnsFor(4, phoneWidth), 2);
    });

    test('en un ancho mayor caben más por fila', () {
      expect(QuickActionsGrid.columnsFor(4, 568), 4);
    });
  });

  testWidgets('las opciones de un grupo se ven directamente, bajo el nombre del grupo en el idioma de la app',
      (tester) async {
    await pumpWithRealTranslations(tester, home: (_) => _grid(_groupsOfTheUserRole()));

    expect(find.text('Resultados y estadísticas'), findsOneWidget);
    expect(find.text('Partidos'), findsOneWidget);
    expect(find.text('Instalaciones'), findsOneWidget);
    expect(find.text('Canchas'), findsOneWidget);

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

    await pumpWithRealTranslations(tester, home: (_) => _grid([item]));

    expect(find.text('Grupo nuevo'), findsOneWidget);
    expect(find.text('Opción'), findsOneWidget);
    expect(find.text('menu.admin.group_que_no_existe'), findsNothing);
  });

  testWidgets('en inglés los bloques se leen en inglés', (tester) async {
    await pumpWithRealTranslations(tester, locale: const Locale('en'), home: (_) => _grid(_groupsOfTheUserRole()));

    expect(find.text('Results and statistics'), findsOneWidget);
    expect(find.text('Facilities'), findsOneWidget);
  });
}
