import 'package:sport_platform/core/constants/app_constants.dart';

/// Por qué una contraseña nueva no sirve, antes de preguntarle al backend.
enum PasswordIssue {
  empty('empty'),
  tooShort('too_short'),
  tooLong('too_long'),
  sameAsCurrent('same_as_current'),
  mismatch('mismatch');

  const PasswordIssue(this.code);

  final String code;

  String get translationKey => 'account.validation.$code';
}

/// La contraseña nueva cumple la política del backend y es distinta de la actual; null si sirve.
PasswordIssue? checkNewPassword(String value, {String? currentPassword}) {
  if (value.isEmpty) return PasswordIssue.empty;
  if (value.length < AppConstants.minPasswordLength.value) return PasswordIssue.tooShort;
  if (value.length > AppConstants.maxPasswordLength.value) return PasswordIssue.tooLong;
  if (currentPassword != null && value == currentPassword) return PasswordIssue.sameAsCurrent;
  return null;
}

/// La confirmación repite la contraseña nueva; null si coincide.
PasswordIssue? checkConfirmation(String newPassword, String confirmation) {
  if (confirmation.isEmpty) return PasswordIssue.empty;
  return confirmation == newPassword ? null : PasswordIssue.mismatch;
}
