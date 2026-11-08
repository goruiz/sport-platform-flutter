import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    test('cada valor sale con su tipo, sin conversiones', () {
      final String name = AppConstants.appName.value;
      final int minPasswordLength = AppConstants.minPasswordLength.value;
      final Duration debounce = AppConstants.searchDebounce.value;

      expect(name, isNotEmpty);
      expect(minPasswordLength, lessThan(AppConstants.maxPasswordLength.value));
      expect(debounce, greaterThan(Duration.zero));
    });

    test('asText sirve para rellenar el {} de una traducción', () {
      expect(AppConstants.minPasswordLength.asText, '${AppConstants.minPasswordLength.value}');
    });

    test('las fechas de los selectores salen de los años y el rango no está al revés', () {
      expect(AppConstants.minPickerDate, DateTime(AppConstants.minPickerYear.value));
      expect(AppConstants.maxPickerDate, DateTime(AppConstants.maxPickerYear.value));
      expect(AppConstants.minPickerDate.isBefore(AppConstants.maxPickerDate), isTrue);
    });
  });
}
