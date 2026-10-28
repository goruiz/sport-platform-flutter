import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/core/utils/text_folding.dart';

void main() {
  test('pasa a minúsculas y quita las tildes, la diéresis, la eñe y la cedilla', () {
    expect(foldForComparison('ÁLAMO Cámara Pingüino Ñandú François'), 'alamo camara pinguino nandu francois');
  });

  test('deja igual lo que no tiene tilde, incluidos los números y los signos', () {
    expect(foldForComparison('Cancha 1 - Norte'), 'cancha 1 - norte');
  });

  test('con eso "Álamo" ordena junto a las A y "camara" encuentra "Cámara"', () {
    final names = ['zeta', 'Álamo', 'beta']..sort((a, b) => foldForComparison(a).compareTo(foldForComparison(b)));

    expect(names, ['Álamo', 'beta', 'zeta']);
    expect(foldForComparison('Cámara').contains(foldForComparison('camara')), isTrue);
  });
}
