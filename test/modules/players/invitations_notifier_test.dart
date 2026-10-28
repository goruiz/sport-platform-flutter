import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_platform/core/services/auth_storage.dart';
import 'package:sport_platform/core/services/session_service.dart';
import 'package:sport_platform/core/services/user_session.dart';
import 'package:sport_platform/modules/players/data/datasource/team_invitations_service.dart';
import 'package:sport_platform/modules/players/data/models/team_invitation_model.dart';
import 'package:sport_platform/modules/players/domain/enums/team_invitation_error.dart';
import 'package:sport_platform/modules/players/presentation/providers/invitations_notifier.dart';

class _FakeInvitationsService extends TeamInvitationsService {
  List<TeamInvitationModel> invitations = [];
  Object? failure;
  /// La sesión nueva que el backend manda al aceptar (null: un backend que aún no la manda).
  String? newToken;
  int loads = 0;
  final answered = <String>[];

  @override
  Future<List<TeamInvitationModel>> getMine() async {
    loads++;
    return invitations;
  }

  @override
  Future<String?> accept(String invitationId) async {
    if (failure != null) throw failure!;
    answered.add('accept:$invitationId');
    invitations = invitations
        .where((invitation) => invitation.id != invitationId)
        .toList();
    return newToken;
  }

  @override
  Future<void> decline(String invitationId) async {
    if (failure != null) throw failure!;
    answered.add('decline:$invitationId');
    invitations = invitations
        .where((invitation) => invitation.id != invitationId)
        .toList();
  }
}

DioException _backendRefusal(String code) => DioException(
  requestOptions: RequestOptions(path: '/team-invitations/x/accept'),
  response: Response(
    requestOptions: RequestOptions(path: '/team-invitations/x/accept'),
    statusCode: 400,
    data: {'success': false, 'status': 400, 'message': code},
  ),
);

// JWT sin firma verificable: el payload es {"id":"user-1","email":"juan@email.com"}.
const _newToken =
    'eyJhbGciOiJIUzI1NiJ9.eyJpZCI6InVzZXItMSIsImVtYWlsIjoianVhbkBlbWFpbC5jb20ifQ.firma';

void main() {
  late _FakeInvitationsService service;
  late int organizationStateResets;
  late InvitationsNotifier notifier;

  const tigres = TeamInvitationModel(
    id: 'inv-1',
    teamId: 't1',
    teamName: 'Tigres',
  );
  const leones = TeamInvitationModel(
    id: 'inv-2',
    teamId: 't2',
    teamName: 'Leones',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    organizationStateResets = 0;
    service = _FakeInvitationsService()..invitations = [tigres, leones];
    notifier = InvitationsNotifier(
      service,
      SessionService(
        resetSessionScopedState: () {},
        resetOrganizationScopedState: () => organizationStateResets++,
      ),
    );
  });

  tearDown(() => notifier.dispose());

  test('antes de cargar no afirma que no haya invitaciones', () {
    expect(notifier.loadedOnce, isFalse);
    expect(notifier.pendingCount, 0);
  });

  test('carga las invitaciones pendientes y las cuenta', () async {
    await notifier.load();

    expect(notifier.loadedOnce, isTrue);
    expect(notifier.pendingCount, 2);
    expect(notifier.invitations.map((invitation) => invitation.teamName), [
      'Tigres',
      'Leones',
    ]);
  });

  test('aceptar una invitación la responde y vuelve a leer la lista', () async {
    await notifier.load();

    final failure = await notifier.accept('inv-1');

    expect(failure, isNull);
    expect(service.answered, ['accept:inv-1']);
    expect(notifier.invitations.map((invitation) => invitation.id), ['inv-2']);
  });

  test(
    'aceptar renueva la sesión con el token nuevo y descarta lo de la organización anterior',
    () async {
      await AuthStorage.saveToken('token-viejo');
      service.newToken = _newToken;

      await notifier.accept('inv-1');

      expect(await AuthStorage.getToken(), _newToken);
      expect(UserSession.current?.id, 'user-1');
      expect(organizationStateResets, 1);
    },
  );

  test('si el backend no manda sesión nueva, aceptar deja la que había', () async {
    await AuthStorage.saveToken('token-viejo');

    await notifier.accept('inv-1');

    expect(await AuthStorage.getToken(), 'token-viejo');
    expect(organizationStateResets, 0);
  });

  test('rechazar una invitación la quita de la lista', () async {
    await notifier.load();

    final failure = await notifier.decline('inv-2');

    expect(failure, isNull);
    expect(service.answered, ['decline:inv-2']);
    expect(notifier.pendingCount, 1);
  });

  test(
    'si el backend la rechaza devuelve la clave del motivo y relee la lista',
    () async {
      await notifier.load();
      service.failure = _backendRefusal('EXPIRED');
      final loadsBefore = service.loads;

      final failure = await notifier.accept('inv-1');

      expect(failure, 'invitations.errors.EXPIRED');
      expect(service.loads, loadsBefore + 1);
    },
  );

  test('un fallo sin motivo conocido devuelve el mensaje genérico', () async {
    await notifier.load();
    service.failure = Exception('sin red');

    expect(await notifier.accept('inv-1'), 'invitations.error_generic');
    expect(await notifier.decline('inv-1'), 'invitations.error_generic');
  });

  test(
    'si falla la carga guarda la clave del error y no inventa invitaciones',
    () async {
      final failingNotifier = InvitationsNotifier(
        _FailingInvitationsService(),
        SessionService(resetSessionScopedState: () {}),
      );

      await failingNotifier.load();

      expect(failingNotifier.error, 'invitations.error_generic');
      expect(failingNotifier.loadedOnce, isTrue);
      expect(failingNotifier.pendingCount, 0);
      failingNotifier.dispose();
    },
  );

  test('clear olvida lo del usuario anterior', () async {
    await notifier.load();

    notifier.clear();

    expect(notifier.pendingCount, 0);
    expect(notifier.loadedOnce, isFalse);
  });

  group('TeamInvitationError', () {
    test('reconoce los cuatro códigos del backend', () {
      expect(
        TeamInvitationError.fromCode('NOT_PENDING'),
        TeamInvitationError.notPending,
      );
      expect(
        TeamInvitationError.fromCode('EXPIRED'),
        TeamInvitationError.expired,
      );
      expect(
        TeamInvitationError.fromCode('TEAM_NOT_FOUND'),
        TeamInvitationError.teamNotFound,
      );
      expect(
        TeamInvitationError.fromCode('PLAYER_NOT_FOUND'),
        TeamInvitationError.playerNotFound,
      );
    });

    test('un código desconocido o un error que no es de red es null', () {
      expect(TeamInvitationError.fromCode('OTHER'), isNull);
      expect(TeamInvitationError.fromException(Exception('x')), isNull);
      expect(
        TeamInvitationError.fromException(_backendRefusal('OTHER')),
        isNull,
      );
    });
  });
}

class _FailingInvitationsService extends TeamInvitationsService {
  @override
  Future<List<TeamInvitationModel>> getMine() async =>
      throw Exception('sin red');
}
