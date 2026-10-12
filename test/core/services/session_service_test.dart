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
}
