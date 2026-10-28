import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_platform/core/services/auth_storage.dart';
import 'package:sport_platform/core/services/session_service.dart';
import 'package:sport_platform/core/services/user_session.dart';
import 'package:sport_platform/modules/users/domain/entities/user_entity.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('clear borra token y usuario, y descarta el estado de la sesión', () async {
    await AuthStorage.saveToken('token');
    await UserSession.update(const UserEntity(id: 'user-1'));
    var stateResets = 0;
    final sessionService =
        SessionService(resetSessionScopedState: () => stateResets++);

    await sessionService.clear();

    expect(await AuthStorage.hasToken(), isFalse);
    expect(UserSession.current, isNull);
    expect(stateResets, 1);
  });

  test('replaceToken cambia la sesión por la nueva y descarta solo lo de la organización', () async {
    await AuthStorage.saveToken('token-viejo');
    var sessionResets = 0;
    var organizationResets = 0;
    final sessionService = SessionService(
      resetSessionScopedState: () => sessionResets++,
      resetOrganizationScopedState: () => organizationResets++,
    );

    // JWT sin firma verificable: el payload es {"id":"user-1","email":"juan@email.com"}.
    await sessionService.replaceToken(
      'eyJhbGciOiJIUzI1NiJ9.eyJpZCI6InVzZXItMSIsImVtYWlsIjoianVhbkBlbWFpbC5jb20ifQ.firma',
    );

    expect(await AuthStorage.getToken(), startsWith('eyJhbGciOiJIUzI1NiJ9'));
    expect(UserSession.current?.id, 'user-1');
    expect(organizationResets, 1);
    expect(sessionResets, 0);
  });
}
