import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/enums/match_status.dart';
import 'package:sport_platform/modules/matches/data/datasource/match_attendance_service.dart';
import 'package:sport_platform/modules/matches/data/models/match_attendance_model.dart';
import 'package:sport_platform/modules/matches/domain/match_attendance_rules.dart';
import 'package:sport_platform/modules/matches/presentation/providers/match_attendance_notifier.dart';
import 'package:sport_platform/shared/enums/summary_status.dart';

import '../../support/builders.dart';

class _FakePlayersService extends PlayersService {
  final PlayerModel? player;
  final bool fails;

  _FakePlayersService(this.player, {this.fails = false});

  @override
  Future<PlayerModel?> getCurrent() async {
    if (fails) throw Exception('sin red');
    return player;
  }
}

class _FakeAttendanceService extends MatchAttendanceService {
  MatchAttendanceModel current;
  Object? failWith;
  int gets = 0;
  AttendanceStatus? lastAnswer;

  _FakeAttendanceService(this.current);

  @override
  Future<MatchAttendanceModel> get(String matchId) async {
    gets++;
    if (failWith != null) throw failWith!;
    return current;
  }

  @override
  Future<MatchAttendanceModel> respond(String matchId, AttendanceStatus status) async {
    if (failWith != null) throw failWith!;
    lastAnswer = status;
    current = MatchAttendanceModel(
      matchId: matchId,
      confirmedCount: status == AttendanceStatus.confirmed ? 1 : 0,
      declinedCount: status == AttendanceStatus.declined ? 1 : 0,
      myStatus: status,
    );
    return current;
  }

  @override
  Future<MatchAttendanceModel> withdraw(String matchId) async {
    if (failWith != null) throw failWith!;
    current = MatchAttendanceModel(matchId: matchId);
    return current;
  }
}

DioException _rejection(String message) => DioException(
      requestOptions: RequestOptions(path: '/matches/m1/attendance'),
      response: Response(
        requestOptions: RequestOptions(path: '/matches/m1/attendance'),
        statusCode: 400,
        data: {'message': message},
      ),
    );

const _ana = PlayerModel(id: 'ana', firstName: 'Ana', lastName: 'Pérez', email: 'ana@email.com', teamId: 'home');
final _now = DateTime(2026, 11, 7, 12);

void main() {
  group('playsInMatch', () {
    final match = matchOf(homeTeamId: 'home', awayTeamId: 'away', date: DateTime(2026, 11, 10));

    test('juega de local o de visitante', () {
      expect(playsInMatch(match, 'home'), isTrue);
      expect(playsInMatch(match, 'away'), isTrue);
    });

    test('otro equipo, o ninguno, no juega', () {
      expect(playsInMatch(match, 'otro'), isFalse);
      expect(playsInMatch(match, null), isFalse);
      expect(playsInMatch(match, ''), isFalse);
    });
  });

  group('teamOfPlayerInMatch', () {
    final match = matchOf(homeTeamId: 'home', awayTeamId: 'away', date: DateTime(2026, 11, 10));

    test('de los equipos del jugador, el que juega el partido', () {
      expect(teamOfPlayerInMatch(match, ['tigres', 'away']), 'away');
      expect(teamOfPlayerInMatch(match, ['home']), 'home');
    });

    test('si ninguno de sus equipos lo juega, ninguno', () {
      expect(teamOfPlayerInMatch(match, ['tigres', 'pumas']), isNull);
      expect(teamOfPlayerInMatch(match, const []), isNull);
    });
  });

  group('canAnswerAttendance', () {
    test('un partido por jugar admite respuesta', () {
      final match = matchOf(date: DateTime(2026, 11, 10));

      expect(canAnswerAttendance(match, _now), isTrue);
    });

    test('uno reprogramado también', () {
      final match = matchOf(date: DateTime(2026, 11, 10), status: MatchStatus.rescheduled);

      expect(canAnswerAttendance(match, _now), isTrue);
    });

    test('uno que ya empezó no', () {
      final match = matchOf(date: DateTime(2026, 11, 7, 11));

      expect(canAnswerAttendance(match, _now), isFalse);
    });

    test('uno aplazado, suspendido o cancelado no', () {
      for (final status in [MatchStatus.postponed, MatchStatus.suspended, MatchStatus.cancelled]) {
        final match = matchOf(date: DateTime(2026, 11, 10), status: status);

        expect(canAnswerAttendance(match, _now), isFalse, reason: '$status');
      }
    });

    test('uno con resultado no', () {
      final match = matchOf(date: DateTime(2026, 11, 10), homeScore: 1, awayScore: 0);

      expect(canAnswerAttendance(match, _now), isFalse);
    });
  });

  group('splitTeamAttendance', () {
    const attendees = [
      MatchAttendee(playerId: '1', playerName: 'Zoe', teamId: 'home', status: AttendanceStatus.confirmed),
      MatchAttendee(playerId: '2', playerName: 'ana', teamId: 'home', status: AttendanceStatus.confirmed),
      MatchAttendee(playerId: '3', playerName: 'Luis', teamId: 'home', status: AttendanceStatus.declined),
      MatchAttendee(playerId: '4', playerName: 'Rival', teamId: 'away', status: AttendanceStatus.confirmed),
      MatchAttendee(playerId: '5', teamId: 'home', status: AttendanceStatus.confirmed),
    ];

    test('reparte a los del equipo entre los que van y los que no, por nombre', () {
      final team = splitTeamAttendance(attendees, 'home');

      expect(team.confirmed.map((a) => a.playerId), ['2', '1', '5']);
      expect(team.declined.map((a) => a.playerId), ['3']);
    });

    test('no muestra a los del rival', () {
      final team = splitTeamAttendance(attendees, 'home');

      expect(team.confirmed.any((a) => a.teamId == 'away'), isFalse);
    });

    test('sin equipo no hay nada que mostrar', () {
      expect(splitTeamAttendance(attendees, null).hasAnswers, isFalse);
    });
  });

  group('MatchAttendanceModel.fromJson', () {
    test('lee los totales, mi respuesta y quiénes respondieron', () {
      final model = MatchAttendanceModel.fromJson({
        'matchId': 'm1',
        'confirmedCount': 2,
        'declinedCount': 1,
        'myStatus': 'CONFIRMED',
        'attendees': [
          {'playerId': 'p1', 'playerName': 'Ana', 'teamId': 'home', 'status': 'CONFIRMED'},
          {'playerId': 'p2', 'playerName': 'Luis', 'teamId': 'home', 'status': 'DECLINED'},
        ],
      });

      expect(model.confirmedCount, 2);
      expect(model.answeredCount, 3);
      expect(model.myStatus, AttendanceStatus.confirmed);
      expect(model.attendees.map((a) => a.status), [AttendanceStatus.confirmed, AttendanceStatus.declined]);
    });

    test('sin respuesta propia ni lista queda en blanco', () {
      final model = MatchAttendanceModel.fromJson({'matchId': 'm1', 'myStatus': null});

      expect(model.myStatus, isNull);
      expect(model.attendees, isEmpty);
    });

    test('una respuesta con un estado desconocido se omite en vez de romper', () {
      final model = MatchAttendanceModel.fromJson({
        'matchId': 'm1',
        'attendees': [
          {'playerId': 'p1', 'teamId': 'home', 'status': 'QUIZAS'},
        ],
      });

      expect(model.attendees, isEmpty);
    });
  });

  group('MatchAttendanceNotifier', () {
    final openMatch = matchOf(id: 'm1', homeTeamId: 'home', awayTeamId: 'away', date: DateTime(2026, 11, 10));

    MatchAttendanceNotifier notifier({
      PlayerModel? player = _ana,
      _FakeAttendanceService? service,
      bool playerFails = false,
    }) {
      return MatchAttendanceNotifier(
        playersService: _FakePlayersService(player, fails: playerFails),
        service: service ?? _FakeAttendanceService(const MatchAttendanceModel(matchId: 'm1')),
        match: openMatch,
        clock: () => _now,
      );
    }

    test('un jugador de uno de los equipos ve la asistencia y puede responder', () async {
      final subject = notifier();

      await subject.load();

      expect(subject.status, SummaryStatus.ready);
      expect(subject.isParticipant, isTrue);
      expect(subject.myTeamId, 'home');
      expect(subject.canAnswer, isTrue);
    });

    test('quien juega en varios equipos participa con el que juega este partido, no con el último al que entró', () async {
      final subject = notifier(
        player: _ana.copyWith(
          teamId: 'tigres',
          teams: const [PlayerTeam(teamId: 'tigres', teamName: 'Tigres'), PlayerTeam(teamId: 'home', teamName: 'Local')],
        ),
      );

      await subject.load();

      expect(subject.isParticipant, isTrue);
      expect(subject.myTeamId, 'home');
    });

    test('quien no juega en el partido no ve nada y ni se lee la asistencia', () async {
      final service = _FakeAttendanceService(const MatchAttendanceModel(matchId: 'm1'));
      final subject = notifier(
        player: _ana.copyWith(teamId: 'ajeno'),
        service: service,
      );

      await subject.load();

      expect(subject.isParticipant, isFalse);
      expect(subject.myTeamId, isNull);
      expect(service.gets, 0);
    });

    test('una cuenta sin jugador tampoco participa', () async {
      final subject = notifier(player: null);

      await subject.load();

      expect(subject.isParticipant, isFalse);
    });

    test('responder guarda la respuesta y deja la asistencia al día', () async {
      final service = _FakeAttendanceService(const MatchAttendanceModel(matchId: 'm1'));
      final subject = notifier(service: service);
      await subject.load();

      final problem = await subject.answer(AttendanceStatus.confirmed);

      expect(problem, isNull);
      expect(service.lastAnswer, AttendanceStatus.confirmed);
      expect(subject.attendance?.myStatus, AttendanceStatus.confirmed);
      expect(subject.isSaving, isFalse);
    });

    test('quitar la respuesta la borra', () async {
      final service = _FakeAttendanceService(const MatchAttendanceModel(matchId: 'm1', myStatus: AttendanceStatus.declined));
      final subject = notifier(service: service);
      await subject.load();

      final problem = await subject.clearAnswer();

      expect(problem, isNull);
      expect(subject.attendance?.myStatus, isNull);
    });

    test('un rechazo del backend se explica con su frase', () async {
      final service = _FakeAttendanceService(const MatchAttendanceModel(matchId: 'm1'));
      final subject = notifier(service: service);
      await subject.load();
      service.failWith = _rejection('MATCH_NOT_OPEN');

      final problem = await subject.answer(AttendanceStatus.confirmed);

      expect(problem, 'match_detail.attendance.error_closed');
    });

    test('un fallo sin código dice la frase general', () async {
      final service = _FakeAttendanceService(const MatchAttendanceModel(matchId: 'm1'));
      final subject = notifier(service: service);
      await subject.load();
      service.failWith = Exception('sin red');

      final problem = await subject.answer(AttendanceStatus.declined);

      expect(problem, 'match_detail.attendance.error_save');
    });

    test('si falla la lectura de un jugador del partido, lo dice y se puede reintentar', () async {
      final service = _FakeAttendanceService(const MatchAttendanceModel(matchId: 'm1'))
        ..failWith = Exception('sin red');
      final subject = notifier(service: service);

      await subject.load();

      expect(subject.isParticipant, isTrue);
      expect(subject.status, SummaryStatus.failed);
      expect(subject.loadErrorKey, 'match_detail.attendance.error_load');

      service.failWith = null;
      await subject.load();

      expect(subject.status, SummaryStatus.ready);
      expect(subject.loadErrorKey, isNull);
    });

    test('si ni siquiera se puede leer al jugador, no se muestra nada', () async {
      final subject = notifier(playerFails: true);

      await subject.load();

      expect(subject.isParticipant, isFalse);
    });

    test('un partido que ya empezó se ve pero no se puede responder', () async {
      final started = matchOf(id: 'm1', homeTeamId: 'home', date: DateTime(2026, 11, 7, 10));
      final subject = MatchAttendanceNotifier(
        playersService: _FakePlayersService(_ana),
        service: _FakeAttendanceService(const MatchAttendanceModel(matchId: 'm1')),
        match: started,
        clock: () => _now,
      );

      await subject.load();

      expect(subject.isParticipant, isTrue);
      expect(subject.canAnswer, isFalse);
    });
  });
}
