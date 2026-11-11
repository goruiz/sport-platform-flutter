import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/players/domain/enums/category_eligibility_issue.dart';
import 'package:sport_platform/modules/players/presentation/widgets/category_eligibility_notice.dart';
import 'package:sport_platform/modules/users/domain/enums/gender.dart';

import '../../support/real_translations.dart';

DioException _refusedWith(Object? body, {int status = 400}) {
  final request = RequestOptions(path: '/team-invitations/1/accept');
  return DioException(
    requestOptions: request,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: request, statusCode: status, data: body),
  );
}

void main() {
  setUpAll(initRealTranslations);

  group('CategoryEligibilityIssue', () {
    test('se reconoce por el código del backend, y uno desconocido o ausente no es ninguno', () {
      expect(CategoryEligibilityIssue.fromCode('CATEGORY_TOO_YOUNG'), CategoryEligibilityIssue.tooYoung);
      expect(CategoryEligibilityIssue.fromCode('CATEGORY_GENDER_NOT_ALLOWED'), CategoryEligibilityIssue.genderNotAllowed);
      expect(CategoryEligibilityIssue.fromCode('SOMETHING_NEW'), isNull);
      expect(CategoryEligibilityIssue.fromCode(null), isNull);
    });

    test('lee el motivo del mensaje de un rechazo, y nada si es otro error', () {
      expect(
        CategoryEligibilityIssue.fromException(_refusedWith({'message': 'CATEGORY_GENDER_REQUIRED'})),
        CategoryEligibilityIssue.genderRequired,
      );
      expect(CategoryEligibilityIssue.fromException(_refusedWith({'message': 'EXPIRED'})), isNull);
      expect(CategoryEligibilityIssue.fromException(_refusedWith(null, status: 500)), isNull);
      expect(CategoryEligibilityIssue.fromException(StateError('x')), isNull);
    });

    test('vuelve de la clave del texto de rechazo a su motivo', () {
      for (final issue in CategoryEligibilityIssue.values) {
        expect(CategoryEligibilityIssue.fromRefusalKey(issue.refusalKey), issue);
      }
      expect(CategoryEligibilityIssue.fromRefusalKey('invitations.expired'), isNull);
      expect(CategoryEligibilityIssue.fromRefusalKey(null), isNull);
    });

    test('solo los que faltan datos se arreglan completando el perfil; el resto es un «no» de la categoría', () {
      expect(
        CategoryEligibilityIssue.values.where((issue) => issue.needsProfileData),
        [CategoryEligibilityIssue.genderRequired, CategoryEligibilityIssue.birthDateRequired],
      );
    });

    for (final locale in supportedTestLocales) {
      testWidgets('cada motivo tiene su texto de rechazo y de aviso en ${locale.languageCode}', (tester) async {
        var unresolved = <String>[];

        await pumpWithRealTranslations(
          tester,
          locale: locale,
          home: (_) {
            final keys = [
              for (final issue in CategoryEligibilityIssue.values) ...[issue.refusalKey, issue.noticeKey],
              CategoryEligibilityNotice.unknownReasonKey,
            ];
            unresolved = [for (final key in keys) if (key.tr() == key) key];
            return const SizedBox.shrink();
          },
        );

        expect(unresolved, isEmpty);
      });
    }
  });

  group('PlayerModel: lo que dice de cada equipo la categoría', () {
    test('lee el género, la fecha de nacimiento y si puede jugar en cada equipo', () {
      final player = PlayerModel.fromJson({
        'id': 'ana',
        'firstName': 'Ana',
        'lastName': 'Pérez',
        'email': 'ana@email.com',
        'gender': 'FEMALE',
        'birthDate': '2012-03-05',
        'teams': [
          {'teamId': 'a1', 'teamName': 'Leones', 'eligibleForCategory': true},
          {
            'teamId': 'b1',
            'teamName': 'Tigres',
            'eligibleForCategory': false,
            'categoryIneligibility': 'CATEGORY_TOO_YOUNG',
          },
        ],
      });

      expect(player.gender, Gender.female);
      expect(player.birthDate, DateTime(2012, 3, 5));
      expect(player.allTeams.first.cannotPlay, isFalse);
      expect(player.allTeams.last.cannotPlay, isTrue);
      expect(player.allTeams.last.categoryIneligibility, CategoryEligibilityIssue.tooYoung);
    });

    test('con un backend anterior, que no lo manda, el jugador puede jugar y no tiene datos', () {
      final player = PlayerModel.fromJson({
        'id': 'ana',
        'firstName': 'Ana',
        'lastName': 'Pérez',
        'email': 'ana@email.com',
        'teams': [
          {'teamId': 'a1', 'teamName': 'Leones'},
        ],
      });

      expect(player.gender, isNull);
      expect(player.birthDate, isNull);
      expect(player.allTeams.single.cannotPlay, isFalse);
      expect(player.allTeams.single.categoryIneligibility, isNull);
    });

    test('un motivo que esta versión no conoce sigue diciendo que no puede jugar, sin detalle', () {
      final team = PlayerTeam.fromJson({
        'teamId': 'b1',
        'teamName': 'Tigres',
        'eligibleForCategory': false,
        'categoryIneligibility': 'CATEGORY_SOMETHING_NEW',
      });

      expect(team.cannotPlay, isTrue);
      expect(team.categoryIneligibility, isNull);
    });

    test('lo que se guarda y se lee de nuevo conserva la elegibilidad', () {
      final team = PlayerTeam.fromJson({
        'teamId': 'b1',
        'teamName': 'Tigres',
        'eligibleForCategory': false,
        'categoryIneligibility': 'CATEGORY_TOO_OLD',
      });

      final again = PlayerTeam.fromJson(team.toJson());

      expect(again.cannotPlay, isTrue);
      expect(again.categoryIneligibility, CategoryEligibilityIssue.tooOld);
    });
  });
}
