import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/users/domain/enums/gender.dart';
import 'package:sport_platform/modules/users/domain/profile_field_errors.dart';

import '../../support/real_translations.dart';

DioException _refusedWith(Object? body, {int status = 400}) {
  final request = RequestOptions(path: '/users/auth/update-profile');
  return DioException(
    requestOptions: request,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: request, statusCode: status, data: body),
  );
}

void main() {
  setUpAll(initRealTranslations);

  group('Gender', () {
    test('se reconoce por el valor del backend y un valor desconocido o ausente no es ninguno', () {
      expect(Gender.fromApi('MALE'), Gender.male);
      expect(Gender.fromApi('FEMALE'), Gender.female);
      expect(Gender.fromApi('OTHER'), isNull);
      expect(Gender.fromApi(null), isNull);
    });

    for (final locale in supportedTestLocales) {
      testWidgets('cada opción tiene su texto en ${locale.languageCode}', (tester) async {
        var unresolved = <String>[];

        await pumpWithRealTranslations(
          tester,
          locale: locale,
          home: (_) {
            unresolved = [for (final gender in Gender.values) if (gender.translationKey.tr() == gender.translationKey) gender.apiValue];
            return const SizedBox.shrink();
          },
        );

        expect(unresolved, isEmpty);
      });
    }
  });

  group('ProfileFieldErrors.fromException', () {
    test('lee el motivo de cada campo que el backend rechazó', () {
      final errors = ProfileFieldErrors.fromException(
        _refusedWith({'data': {'gender': 'INVALID_GENDER', 'birthDate': 'INVALID_BIRTH_DATE'}}),
      );

      expect(errors.gender, ProfileDataError.invalidGender);
      expect(errors.birthDate, ProfileDataError.invalidBirthDate);
      expect(errors.isEmpty, isFalse);
    });

    test('con un solo campo rechazado, el otro queda sin motivo', () {
      final errors = ProfileFieldErrors.fromException(_refusedWith({'data': {'birthDate': 'INVALID_BIRTH_DATE'}}));

      expect(errors.gender, isNull);
      expect(errors.birthDate, ProfileDataError.invalidBirthDate);
    });

    test('un motivo que no es de estos campos, sin conexión o un error que no es de la petición, queda vacío', () {
      expect(ProfileFieldErrors.fromException(_refusedWith({'data': {'username': 'ALREADY_EXISTS'}})).isEmpty, isTrue);
      expect(ProfileFieldErrors.fromException(_refusedWith(null, status: 500)).isEmpty, isTrue);
      expect(ProfileFieldErrors.fromException(StateError('x')).isEmpty, isTrue);
    });

    for (final locale in supportedTestLocales) {
      testWidgets('cada motivo tiene su texto en ${locale.languageCode}', (tester) async {
        var unresolved = <String>[];

        await pumpWithRealTranslations(
          tester,
          locale: locale,
          home: (_) {
            unresolved = [for (final error in ProfileDataError.values) if (error.translationKey.tr() == error.translationKey) error.code];
            return const SizedBox.shrink();
          },
        );

        expect(unresolved, isEmpty);
      });
    }
  });
}
