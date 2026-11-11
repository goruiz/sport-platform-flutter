import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/core/network/api_error_codes.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/matches/data/datasource/match_disputes_service.dart';
import 'package:sport_platform/modules/matches/data/models/match_dispute_model.dart';
import 'package:sport_platform/modules/matches/domain/match_dispute_rules.dart';
import 'package:sport_platform/modules/matches/presentation/providers/match_result_dispute_notifier.dart';
import 'package:sport_platform/modules/users/data/datasource/account_service.dart';
import 'package:sport_platform/modules/users/domain/enums/account_capability.dart';
import 'package:sport_platform/modules/users/presentation/providers/account_capabilities_notifier.dart';
import 'package:sport_platform/shared/enums/summary_status.dart';

import '../../support/builders.dart';
import '../../support/real_translations.dart';

class _FakeAccountService extends AccountService {
  Set<AccountCapability> capabilities;
  bool fails;
  int reads = 0;

  _FakeAccountService(this.capabilities, {this.fails = false});

  @override
  Future<Set<AccountCapability>> loadCapabilities() async {
    reads++;
    if (fails) throw Exception('sin red');
    return capabilities;
  }
}

class _FakePlayersService extends PlayersService {
  final PlayerModel? player;
  final bool fails;
  int reads = 0;

  _FakePlayersService(this.player, {this.fails = false});

  @override
  Future<PlayerModel?> getCurrent() async {
    reads++;
    if (fails) throw Exception('sin red');
    return player;
  }
}

class _FakeDisputesService extends MatchDisputesService {
  List<MatchDisputeModel> existing;
  Object? failOpenWith;
  int reads = 0;
  Map<String, Object?>? lastOpened;

  _FakeDisputesService(this.existing);

  @override
  Future<List<MatchDisputeModel>> getByMatch(String matchId) async {
    reads++;
    return existing;
  }

  @override
  Future<MatchDisputeModel?> open(
    String matchId, {
    required String teamId,
    required String reason,
    int? proposedHomeScore,
    int? proposedAwayScore,
  }) async {
    if (failOpenWith != null) throw failOpenWith!;
    lastOpened = {'teamId': teamId, 'reason': reason, 'home': proposedHomeScore, 'away': proposedAwayScore};
    return _dispute(id: 'new', teamId: teamId, status: DisputeStatus.open, createdAt: DateTime(2026, 11, 11));
  }
}

MatchDisputeModel _dispute({
  String id = 'd1',
  String teamId = 'home',
  DisputeStatus status = DisputeStatus.open,
  DateTime? createdAt,
}) {
  return MatchDisputeModel(
    id: id,
    matchId: 'match-1',
    status: status,
    teamId: teamId,
    reason: 'El gol no fue nuestro',
    createdAt: createdAt ?? DateTime(2026, 11, 10),
  );
}

DioException _refusedWith(String code, {int status = 400}) {
  final request = RequestOptions(path: '/matches/match-1/disputes');
  return DioException(
    requestOptions: request,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: request, statusCode: status, data: {'message': code}),
  );
}

const _ana = PlayerModel(id: 'ana', firstName: 'Ana', lastName: 'Pérez', email: 'ana@email.com', teamId: 'home');
final _playedMatch = matchOf(date: DateTime(2026, 11, 8), homeScore: 2, awayScore: 1);

MatchResultDisputeNotifier _notifier({
  Set<AccountCapability> capabilities = const {AccountCapability.openMatchDisputes},
  PlayerModel? player = _ana,
  bool playersFail = false,
  bool capabilitiesFail = false,
  List<MatchDisputeModel> disputes = const [],
  _FakeDisputesService? disputesService,
  _FakePlayersService? playersService,
  _FakeAccountService? accountService,
  MatchModel? match,
}) {
  return MatchResultDisputeNotifier(
    capabilities: AccountCapabilitiesNotifier(
      accountService ?? _FakeAccountService(capabilities, fails: capabilitiesFail),
    ),
    playersService: playersService ?? _FakePlayersService(player, fails: playersFail),
    service: disputesService ?? _FakeDisputesService(disputes),
    match: match ?? _playedMatch,
  );
}

void main() {
  setUpAll(initRealTranslations);

  group('AccountCapability', () {
    test('lee las capacidades que conoce e ignora las que no', () {
      expect(
        AccountCapability.setFrom(['OPEN_MATCH_DISPUTES', 'SOMETHING_NEW']),
        {AccountCapability.openMatchDisputes},
      );
    });

    test('sin lista, la cuenta no puede nada extra', () {
      expect(AccountCapability.setFrom(null), isEmpty);
      expect(AccountCapability.setFrom('OPEN_MATCH_DISPUTES'), isEmpty);
      expect(AccountCapability.setFrom(const []), isEmpty);
    });
  });

  group('AccountCapabilitiesNotifier', () {
    test('lee una sola vez y recuerda lo leído', () async {
      final service = _FakeAccountService({AccountCapability.openMatchDisputes});
      final notifier = AccountCapabilitiesNotifier(service);

      expect(notifier.can(AccountCapability.openMatchDisputes), isFalse); // todavía no se sabe
      await notifier.ensureLoaded();
      await notifier.ensureLoaded();

      expect(notifier.can(AccountCapability.openMatchDisputes), isTrue);
      expect(service.reads, 1);
    });

    test('las lecturas simultáneas comparten una sola petición', () async {
      final service = _FakeAccountService({AccountCapability.openMatchDisputes});
      final notifier = AccountCapabilitiesNotifier(service);

      await Future.wait([notifier.ensureLoaded(), notifier.ensureLoaded()]);

      expect(service.reads, 1);
    });

    test('sin respuesta del backend no puede nada, y el próximo intento vuelve a leer', () async {
      final service = _FakeAccountService({AccountCapability.openMatchDisputes}, fails: true);
      final notifier = AccountCapabilitiesNotifier(service);

      expect(await notifier.ensureLoaded(), isEmpty);
      expect(notifier.can(AccountCapability.openMatchDisputes), isFalse);

      service.fails = false;
      await notifier.ensureLoaded();

      expect(notifier.can(AccountCapability.openMatchDisputes), isTrue);
      expect(service.reads, 2);
    });

    test('actualizar trae el rol nuevo, y cerrar la sesión lo olvida', () async {
      final service = _FakeAccountService({});
      final notifier = AccountCapabilitiesNotifier(service);
      await notifier.ensureLoaded();

      service.capabilities = {AccountCapability.openMatchDisputes};
      await notifier.refresh();
      expect(notifier.can(AccountCapability.openMatchDisputes), isTrue);

      notifier.clear();
      expect(notifier.can(AccountCapability.openMatchDisputes), isFalse);
    });

    test('si actualizar falla, conserva lo que ya sabía', () async {
      final service = _FakeAccountService({AccountCapability.openMatchDisputes});
      final notifier = AccountCapabilitiesNotifier(service);
      await notifier.ensureLoaded();

      service.fails = true;
      await notifier.refresh();

      expect(notifier.can(AccountCapability.openMatchDisputes), isTrue);
    });
  });

  group('MatchDisputeModel', () {
    test('lee un aviso con su respuesta', () {
      final dispute = MatchDisputeModel.fromJson({
        'id': 'd1',
        'matchId': 'm1',
        'status': 'REJECTED',
        'teamId': 'home',
        'reason': 'El gol no fue nuestro',
        'proposedHomeScore': 2,
        'proposedAwayScore': 2,
        'createdAt': '2026-11-10T20:30:00',
        'resolutionNote': 'El acta lo confirma',
        'resolvedAt': '2026-11-11T09:00:00',
      })!;

      expect(dispute.status, DisputeStatus.rejected);
      expect(dispute.isOpen, isFalse);
      expect(dispute.hasProposedScore, isTrue);
      expect(dispute.resolutionNote, 'El acta lo confirma');
      expect(dispute.createdAt, DateTime(2026, 11, 10, 20, 30));
    });

    test('un aviso sin marcador propuesto ni respuesta se lee igual', () {
      final dispute = MatchDisputeModel.fromJson({
        'id': 'd1',
        'status': 'OPEN',
        'teamId': 'home',
        'reason': 'Falta un gol',
        'createdAt': '2026-11-10T20:30:00',
      })!;

      expect(dispute.isOpen, isTrue);
      expect(dispute.hasProposedScore, isFalse);
      expect(dispute.resolutionNote, isNull);
    });

    test('un estado que la app no conoce no se puede mostrar', () {
      expect(MatchDisputeModel.fromJson({'id': 'd1', 'status': 'ESCALATED', 'teamId': 'home'}), isNull);
    });
  });

  group('reglas', () {
    test('solo un partido con resultado puede tener un problema con el resultado', () {
      expect(canReportResultProblem(_playedMatch), isTrue);
      expect(canReportResultProblem(matchOf(date: DateTime(2026, 11, 20))), isFalse);
      expect(canReportResultProblem(matchOf(date: DateTime(2026, 11, 8), homeScore: 1)), isFalse);
    });

    test('de los avisos, solo los del equipo y de más nuevo a más antiguo', () {
      final old = _dispute(id: 'old', createdAt: DateTime(2026, 11, 1));
      final recent = _dispute(id: 'recent', createdAt: DateTime(2026, 11, 9));
      final other = _dispute(id: 'other', teamId: 'away');

      expect([for (final d in disputesOfTeam([old, other, recent], 'home')) d.id], ['recent', 'old']);
    });

    test('sin avisos se ofrece avisar', () {
      final state = DisputeCardState.of(const []);

      expect(state.latest, isNull);
      expect(state.canOpenNew, isTrue);
    });

    test('con un aviso esperando respuesta se muestra ese y no se ofrece otro', () {
      final answered = _dispute(id: 'answered', status: DisputeStatus.rejected, createdAt: DateTime(2026, 11, 12));
      final open = _dispute(id: 'open', createdAt: DateTime(2026, 11, 9));

      final state = DisputeCardState.of([answered, open]);

      expect(state.latest?.id, 'open');
      expect(state.canOpenNew, isFalse);
    });

    test('con todos respondidos se muestra el más reciente y se puede avisar de otro problema', () {
      final newer = _dispute(id: 'newer', status: DisputeStatus.accepted, createdAt: DateTime(2026, 11, 9));
      final older = _dispute(id: 'older', status: DisputeStatus.rejected, createdAt: DateTime(2026, 11, 1));

      final state = DisputeCardState.of([newer, older]);

      expect(state.latest?.id, 'newer');
      expect(state.canOpenNew, isTrue);
    });

    group('readProposedScore', () {
      test('las dos casillas vacías: no propone marcador', () {
        final score = readProposedScore('', '  ');

        expect(score.isValid, isTrue);
        expect(score.homeScore, isNull);
        expect(score.awayScore, isNull);
      });

      test('los dos goles escritos: es el marcador propuesto', () {
        final score = readProposedScore(' 2', '0 ');

        expect(score.isValid, isTrue);
        expect(score.homeScore, 2);
        expect(score.awayScore, 0);
      });

      test('los goles de un solo equipo está incompleto', () {
        expect(readProposedScore('2', '').problem, ProposedScoreProblem.incomplete);
        expect(readProposedScore('', '1').problem, ProposedScoreProblem.incomplete);
      });

      test('lo que no es un entero desde 0 no sirve', () {
        expect(readProposedScore('-1', '0').problem, ProposedScoreProblem.invalid);
        expect(readProposedScore('1.5', '0').problem, ProposedScoreProblem.invalid);
        expect(readProposedScore('dos', '0').problem, ProposedScoreProblem.invalid);
      });
    });

    test('cada rechazo del backend se reconoce por su código', () {
      for (final error in MatchDisputeError.values) {
        final codes = ApiErrorCodes.of(_refusedWith(error.backendCode, status: 403));
        expect(MatchDisputeError.fromBackend(codes), error);
      }
      expect(MatchDisputeError.fromBackend(ApiErrorCodes.of(_refusedWith('SOMETHING_NEW'))), isNull);
    });
  });

  group('MatchResultDisputeNotifier', () {
    test('un dirigente de uno de los equipos ve sus avisos, no los del rival', () async {
      final notifier = _notifier(
        disputes: [_dispute(id: 'mine'), _dispute(id: 'rival', teamId: 'away')],
      );

      await notifier.load();

      expect(notifier.status, SummaryStatus.ready);
      expect(notifier.isAvailable, isTrue);
      expect(notifier.myTeamId, 'home');
      expect([for (final d in notifier.disputes) d.id], ['mine']);
    });

    test('quien no tiene la capacidad no ve nada y no se pide nada más', () async {
      final players = _FakePlayersService(_ana);
      final disputes = _FakeDisputesService(const []);
      final notifier = _notifier(capabilities: const {}, playersService: players, disputesService: disputes);

      await notifier.load();

      expect(notifier.status, SummaryStatus.ready);
      expect(notifier.isAvailable, isFalse);
      expect(notifier.myTeamId, isNull);
      expect(players.reads, 0);
      expect(disputes.reads, 0);
    });

    test('un partido sin resultado no tiene nada que avisar', () async {
      final disputes = _FakeDisputesService(const []);
      final notifier = _notifier(disputesService: disputes, match: matchOf(date: DateTime(2026, 11, 20)));

      await notifier.load();

      expect(notifier.isAvailable, isFalse);
      expect(disputes.reads, 0);
    });

    test('si su equipo no juega el partido, no se le ofrece', () async {
      final notifier = _notifier(
        player: const PlayerModel(id: 'x', firstName: 'X', lastName: 'Y', email: 'x@y.com', teamId: 'otro'),
      );

      await notifier.load();

      expect(notifier.isAvailable, isFalse);
    });

    test('una cuenta sin jugador no puede avisar', () async {
      final notifier = _notifier(player: null);

      await notifier.load();

      expect(notifier.isAvailable, isFalse);
      expect(notifier.status, SummaryStatus.ready);
    });

    test('sin conexión para saber su rol no ofrece nada, sin un error que mostrar', () async {
      final notifier = _notifier(capabilitiesFail: true);

      await notifier.load();

      expect(notifier.isAvailable, isFalse);
      expect(notifier.status, SummaryStatus.ready);
    });

    test('si falla leer sus avisos, lo dice y deja reintentar', () async {
      final notifier = _notifier(playersFail: true);

      await notifier.load();

      expect(notifier.status, SummaryStatus.failed);
      expect(notifier.loadErrorKey, 'match_detail.dispute.error_load');
      expect(notifier.isAvailable, isFalse);
    });

    test('actualizar a mano vuelve a leer el rol', () async {
      final account = _FakeAccountService(const {});
      final notifier = _notifier(accountService: account);
      await notifier.load();
      expect(notifier.isAvailable, isFalse);

      account.capabilities = {AccountCapability.openMatchDisputes};
      await notifier.load(forceCapabilities: true);

      expect(notifier.isAvailable, isTrue);
    });

    test('avisar manda el equipo, lo que pasó y el marcador, y agrega el aviso al principio', () async {
      final service = _FakeDisputesService([_dispute(id: 'old', status: DisputeStatus.rejected)]);
      final notifier = _notifier(disputesService: service);
      await notifier.load();

      final problem = await notifier.report(reason: 'Falta un gol', proposedHomeScore: 3, proposedAwayScore: 1);

      expect(problem, isNull);
      expect(service.lastOpened, {'teamId': 'home', 'reason': 'Falta un gol', 'home': 3, 'away': 1});
      expect([for (final d in notifier.disputes) d.id], ['new', 'old']);
      expect(notifier.isSaving, isFalse);
    });

    test('un rechazo del backend vuelve como la clave de su frase', () async {
      final service = _FakeDisputesService(const []);
      final notifier = _notifier(disputesService: service);
      await notifier.load();

      service.failOpenWith = _refusedWith('WINDOW_CLOSED');
      expect(await notifier.report(reason: 'x'), 'match_detail.dispute.errors.WINDOW_CLOSED');

      service.failOpenWith = _refusedWith('NOT_ALLOWED_FOR_TEAM', status: 403);
      expect(await notifier.report(reason: 'x'), 'match_detail.dispute.errors.NOT_ALLOWED_FOR_TEAM');

      service.failOpenWith = Exception('sin red');
      expect(await notifier.report(reason: 'x'), 'match_detail.dispute.error_save');
      expect(notifier.disputes, isEmpty);
    });

    test('quien no puede avisar no envía nada', () async {
      final service = _FakeDisputesService(const []);
      final notifier = _notifier(capabilities: const {}, disputesService: service);
      await notifier.load();

      expect(await notifier.report(reason: 'x'), isNull);
      expect(service.lastOpened, isNull);
    });
  });

  for (final locale in supportedTestLocales) {
    testWidgets('cada texto del aviso de un problema existe en ${locale.languageCode}', (tester) async {
      var unresolved = <String>[];

      await pumpWithRealTranslations(
        tester,
        locale: locale,
        home: (_) {
          const keys = [
            'title',
            'hint',
            'report',
            'report_again',
            'sheet_title',
            'current_result',
            'reason_label',
            'reason_hint',
            'score_title',
            'send',
            'sent',
            'status_open',
            'status_accepted',
            'status_rejected',
            'your_reason',
            'proposed_score',
            'organizer_note',
            'error_load',
            'error_save',
          ];
          final all = [
            for (final key in keys) 'match_detail.dispute.$key',
            for (final error in MatchDisputeError.values) error.translationKey,
          ];
          unresolved = [for (final key in all) if (key.tr() == key) key];
          return const SizedBox.shrink();
        },
      );

      expect(unresolved, isEmpty);
    });
  }
}
