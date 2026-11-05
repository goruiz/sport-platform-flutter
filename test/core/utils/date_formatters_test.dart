import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/core/utils/date_formatters.dart';

import '../../support/real_translations.dart';

void main() {
  setUpAll(initRealTranslations);

  // Un jueves a media tarde: el reloj de las pruebas.
  final now = DateTime(2026, 11, 5, 15, 30);

  group('friendlyDay', () {
    test('hoy, mañana y ayer se dicen con palabras', () {
      // Sin EasyLocalization montado `tr()` devuelve la propia clave: lo que se prueba es qué clave se elige.
      expect(DateFormatters.friendlyDay(DateTime(2026, 11, 5, 22), 'es', now: now), 'common.today');
      expect(DateFormatters.friendlyDay(DateTime(2026, 11, 6, 8), 'es', now: now), 'common.tomorrow');
      expect(DateFormatters.friendlyDay(DateTime(2026, 11, 4, 8), 'es', now: now), 'common.yesterday');
    });

    test('un día lejano se escribe en el idioma pedido', () {
      expect(DateFormatters.friendlyDay(DateTime(2026, 11, 12), 'es', now: now), 'jue, 12 nov');
      expect(DateFormatters.friendlyDay(DateTime(2026, 11, 12), 'en', now: now), 'Thu, Nov 12');
    });

    test('con otro año se agrega el año', () {
      expect(DateFormatters.friendlyDay(DateTime(2027, 2, 3), 'es', now: now), 'mié, 3 feb 2027');
    });

    test('la hora del día no cambia el resultado', () {
      final lateNow = DateTime(2026, 11, 5, 23, 59);
      expect(DateFormatters.friendlyDay(DateTime(2026, 11, 6, 0, 1), 'es', now: lateNow), 'common.tomorrow');
    });
  });

  group('shortRange', () {
    test('en el año actual no repite el año', () {
      expect(
        DateFormatters.shortRange(DateTime(2026, 11, 12), DateTime(2026, 11, 30), 'es', now: now),
        '12 nov – 30 nov',
      );
    });

    test('si el rango sale del año actual agrega el año', () {
      expect(
        DateFormatters.shortRange(DateTime(2026, 12, 20), DateTime(2027, 1, 10), 'es', now: now),
        '20 dic 2026 – 10 ene 2027',
      );
    });
  });

  test('time da la hora de 24 h con ceros a la izquierda', () {
    expect(DateFormatters.time(DateTime(2026, 11, 5, 8, 5)), '08:05');
    expect(DateFormatters.time(DateTime(2026, 11, 5, 21, 30)), '21:30');
  });
}
