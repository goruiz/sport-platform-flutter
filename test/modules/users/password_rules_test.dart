import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/core/constants/app_constants.dart';
import 'package:sport_platform/modules/users/domain/password_rules.dart';

void main() {
  group('checkNewPassword', () {
    test('una contraseña vacía no sirve', () {
      expect(checkNewPassword(''), PasswordIssue.empty);
    });

    test('respeta el mínimo y el máximo de la política del backend', () {
      final minLength = AppConstants.minPasswordLength.value;
      final maxLength = AppConstants.maxPasswordLength.value;

      expect(checkNewPassword('a' * (minLength - 1)), PasswordIssue.tooShort);
      expect(checkNewPassword('a' * minLength), isNull);
      expect(checkNewPassword('a' * maxLength), isNull);
      expect(checkNewPassword('a' * (maxLength + 1)), PasswordIssue.tooLong);
    });

    test('no puede ser igual a la actual', () {
      expect(checkNewPassword('Secreta123', currentPassword: 'Secreta123'), PasswordIssue.sameAsCurrent);
      expect(checkNewPassword('Secreta124', currentPassword: 'Secreta123'), isNull);
    });
  });

  group('checkConfirmation', () {
    test('debe repetir la contraseña nueva', () {
      expect(checkConfirmation('Secreta123', ''), PasswordIssue.empty);
      expect(checkConfirmation('Secreta123', 'Secreta124'), PasswordIssue.mismatch);
      expect(checkConfirmation('Secreta123', 'Secreta123'), isNull);
    });
  });

  test('cada motivo apunta a su clave de traducción', () {
    expect(PasswordIssue.tooShort.translationKey, 'account.validation.too_short');
  });
}
