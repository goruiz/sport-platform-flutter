import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/players/domain/enums/team_invitation_error.dart';

import '../../support/real_translations.dart';

DioException _refusedWith(Object? body, {int status = 400}) {
  final request = RequestOptions(path: '/players/auth/register');
  return DioException(
    requestOptions: request,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: request, statusCode: status, data: body),
  );
}

void main() {
  setUpAll(initRealTranslations);

  group('fromException', () {
    test('lee el código que el backend manda en el mensaje, sea un 400 o un 404', () {
      expect(
        TeamInvitationError.fromException(_refusedWith({'message': 'EXPIRED'})),
        TeamInvitationError.expired,
      );
      expect(
        TeamInvitationError.fromException(_refusedWith({'message': 'INVITATION_NOT_FOUND'}, status: 404)),
        TeamInvitationError.invitationNotFound,
      );
    });

    test('un mensaje que no es un código, o un error que no es de la petición, no es uno de estos', () {
      expect(
        TeamInvitationError.fromException(_refusedWith({'message': 'Invalid invitation token'})),
        isNull,
      );
      expect(TeamInvitationError.fromException(_refusedWith(null)), isNull);
      expect(TeamInvitationError.fromException(StateError('x')), isNull);
    });
  });

  test('el registro explica cada motivo con su texto, y el equipo borrado con el de la bandeja', () {
    expect(TeamInvitationError.notPending.registrationTranslationKey, 'invite_register.error_token_used');
    expect(TeamInvitationError.expired.registrationTranslationKey, 'invite_register.error_token_expired');
    expect(TeamInvitationError.invitationNotFound.registrationTranslationKey, 'invite_register.error_token_invalid');
    expect(TeamInvitationError.teamNotFound.registrationTranslationKey, 'invitations.errors.TEAM_NOT_FOUND');
    expect(TeamInvitationError.playerNotFound.registrationTranslationKey, 'invite_register.error_generic');
  });

  for (final locale in supportedTestLocales) {
    testWidgets('cada motivo tiene texto en ${locale.languageCode}, en la bandeja y en el registro', (tester) async {
      var unresolved = <String>[];

      await pumpWithRealTranslations(
        tester,
        locale: locale,
        home: (_) {
          final keys = [
            for (final error in TeamInvitationError.values) ...[error.translationKey, error.registrationTranslationKey],
          ];
          unresolved = [for (final key in keys) if (key.tr() == key) key];
          return const SizedBox.shrink();
        },
      );

      expect(unresolved, isEmpty, reason: 'sin traducción en ${locale.languageCode}');
    });
  }
}
