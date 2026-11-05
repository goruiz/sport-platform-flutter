import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/shared/widgets/initials_avatar.dart';

void main() {
  group('initialsOf', () {
    test('toma la inicial de las dos primeras palabras', () {
      expect(InitialsAvatar.initialsOf('Los Halcones'), 'LH');
      expect(InitialsAvatar.initialsOf('  club   deportivo norte '), 'CD');
    });

    test('con una sola palabra toma sus dos primeras letras', () {
      expect(InitialsAvatar.initialsOf('Tigres'), 'TI');
      expect(InitialsAvatar.initialsOf('X'), 'X');
    });

    test('un nombre vacío da un signo de interrogación', () {
      expect(InitialsAvatar.initialsOf('   '), '?');
    });
  });

  group('colorOf', () {
    test('el mismo nombre da siempre el mismo color', () {
      expect(InitialsAvatar.colorOf('Los Halcones'), InitialsAvatar.colorOf('Los Halcones'));
    });

    test('equipos distintos suelen tener colores distintos', () {
      final colors = {
        for (final name in ['Los Halcones', 'Tigres', 'Águilas', 'Real Norte', 'Deportivo Sur'])
          InitialsAvatar.colorOf(name),
      };
      expect(colors.length, greaterThan(1));
    });
  });
}
