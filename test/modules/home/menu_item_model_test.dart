import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';

// Sin un EasyLocalization inicializado `tr()` responde la propia clave, que es justo el caso que el modelo debe cubrir:
// un diccionario que no conoce la clave de la base de datos.
void main() {
  group('MenuItemModel.fromJson', () {
    test('lee las claves de traducción del nombre y de la descripción', () {
      final item = MenuItemModel.fromJson({
        'id': '1',
        'name': 'Partidos',
        'translationKey': 'home.action_my_matches',
        'description': 'Todos los partidos de la competición',
        'descriptionTranslationKey': 'menu.matches_description',
      });

      expect(item.translationKey, 'home.action_my_matches');
      expect(item.descriptionTranslationKey, 'menu.matches_description');
    });

    test('conserva la clave de la descripción al copiarse con otros hijos', () {
      final item = MenuItemModel.fromJson({
        'id': '1',
        'name': 'Competición',
        'descriptionTranslationKey': 'menu.admin.group_competition_description',
      });

      expect(
        item.copyWith(children: const []).descriptionTranslationKey,
        'menu.admin.group_competition_description',
      );
    });
  });

  group('MenuItemModel.localizedName', () {
    test('usa el nombre de la base cuando la opción no tiene clave', () {
      const item = MenuItemModel(id: '1', name: 'Inicio');

      expect(item.localizedName, 'Inicio');
    });

    test('usa el nombre de la base cuando el diccionario no conoce la clave, en vez de enseñar la clave', () {
      const item = MenuItemModel(
        id: '1',
        name: 'Ranking de la liga',
        translationKey: 'menu.clave_que_no_existe',
      );

      expect(item.localizedName, 'Ranking de la liga');
    });
  });

  group('MenuItemModel.localizedDescription', () {
    test('es nula cuando la opción no tiene descripción', () {
      const item = MenuItemModel(id: '1', name: 'Inicio');

      expect(item.localizedDescription, isNull);
    });

    test('es nula cuando la descripción está vacía', () {
      const item = MenuItemModel(id: '1', name: 'Inicio', description: '');

      expect(item.localizedDescription, isNull);
    });

    test('usa la descripción de la base cuando no hay clave o el diccionario no la conoce', () {
      const withoutKey = MenuItemModel(
        id: '1',
        name: 'Perfil',
        description: 'Tus datos y tu cuenta',
      );
      const unknownKey = MenuItemModel(
        id: '2',
        name: 'Perfil',
        description: 'Tus datos y tu cuenta',
        descriptionTranslationKey: 'menu.clave_que_no_existe',
      );

      expect(withoutKey.localizedDescription, 'Tus datos y tu cuenta');
      expect(unknownKey.localizedDescription, 'Tus datos y tu cuenta');
    });
  });
}
