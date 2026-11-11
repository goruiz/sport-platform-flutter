import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/core/constants/app_constants.dart';
import 'package:sport_platform/modules/users/domain/birth_date_rules.dart';

void main() {
  final today = DateTime(2026, 11, 10);

  group('checkBirthDate', () {
    test('sin fecha es «vacía»: cada pantalla lo dice con su propio texto', () {
      expect(checkBirthDate(null, today: today), BirthDateIssue.empty);
      expect(BirthDateIssue.empty.translationKey, isNull);
    });

    test('una fecha de hoy o del pasado sirve', () {
      expect(checkBirthDate(DateTime(2026, 11, 10), today: today), isNull);
      expect(checkBirthDate(DateTime(2012, 3, 5), today: today), isNull);
    });

    test('una fecha futura no sirve, aunque sea de mañana', () {
      expect(checkBirthDate(DateTime(2026, 11, 11), today: today), BirthDateIssue.inTheFuture);
      expect(BirthDateIssue.inTheFuture.translationKey, 'profile.birth_date_future');
    });

    test('la hora no cuenta: las 23:59 de hoy siguen siendo hoy', () {
      expect(checkBirthDate(DateTime(2026, 11, 10, 23, 59), today: today), isNull);
    });

    test('una fecha de alguien de más años de los que puede tener una persona no sirve', () {
      final limit = AppConstants.maxPersonAgeYears.value;
      expect(checkBirthDate(DateTime(today.year - limit, 11, 10), today: today), isNull);
      expect(checkBirthDate(DateTime(today.year - limit, 11, 9), today: today), BirthDateIssue.tooOld);
      expect(BirthDateIssue.tooOld.translationKey, 'profile.birth_date_too_old');
    });
  });

  group('el selector de fechas', () {
    test('abre en una fecha razonable, no en hoy, y no ofrece más atrás de lo que el backend acepta', () {
      expect(initialBirthDateForPicker(today), DateTime(today.year - AppConstants.birthDatePickerInitialAgeYears.value, 11, 10));
      expect(oldestBirthDate(today), DateTime(today.year - AppConstants.maxPersonAgeYears.value, 11, 10));
    });
  });

  group('formatBirthDateForApi y parseBirthDate', () {
    test('escriben el día como lo espera el backend, con ceros a la izquierda', () {
      expect(formatBirthDateForApi(DateTime(2012, 3, 5)), '2012-03-05');
      expect(formatBirthDateForApi(DateTime(987, 1, 2)), '0987-01-02');
    });

    test('leen «yyyy-MM-dd» por partes, sin correrse de día', () {
      final parsed = parseBirthDate('2012-03-05');

      expect(parsed, DateTime(2012, 3, 5));
      expect(parsed!.hour, 0);
    });

    test('ida y vuelta devuelven el mismo día', () {
      final day = DateTime(2000, 12, 31);

      expect(parseBirthDate(formatBirthDateForApi(day)), day);
    });

    test('lo que no es una fecha (nada, otro tipo, un día que no existe) es null', () {
      expect(parseBirthDate(null), isNull);
      expect(parseBirthDate(20120305), isNull);
      expect(parseBirthDate('no es una fecha'), isNull);
      expect(parseBirthDate('2026-02-31'), isNull);
    });
  });
}
