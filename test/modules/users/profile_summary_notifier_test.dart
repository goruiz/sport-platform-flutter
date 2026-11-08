import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/rankings/data/datasource/player_stats_service.dart';
import 'package:sport_platform/modules/rankings/data/models/player_stats_model.dart';
import 'package:sport_platform/modules/users/presentation/providers/profile_summary_notifier.dart';

class _FakePlayersService extends PlayersService {
  final Future<PlayerModel?> Function() onGetCurrent;

  _FakePlayersService(this.onGetCurrent);

  @override
  Future<PlayerModel?> getCurrent() => onGetCurrent();
}

class _FakePlayerStatsService extends PlayerStatsService {
  final Future<PlayerStatsModel> Function() onGetMine;
  int mineCalls = 0;

  _FakePlayerStatsService(this.onGetMine);

  @override
  Future<PlayerStatsModel> getMine() {
    mineCalls++;
    return onGetMine();
  }
}

const _ana = PlayerModel(id: 'ana', firstName: 'Ana', lastName: 'Pérez', email: 'ana@email.com', teamId: 't1', teamName: 'Tigres');

const _anaTotals = PlayerStatsModel(
  playerId: 'ana',
  teamId: '',
  matchesPlayed: 9,
  goals: 3,
  assists: 1,
  yellowCards: 2,
);

ProfileSummaryNotifier _notifier({
  required Future<PlayerModel?> Function() player,
  Future<PlayerStatsModel> Function()? totals,
  _FakePlayerStatsService? statsService,
}) {
  return ProfileSummaryNotifier(
    playersService: _FakePlayersService(player),
    playerStatsService: statsService ?? _FakePlayerStatsService(totals ?? () async => _anaTotals),
  );
}

void main() {
  test('mientras lee, sus dos bloques están cargando', () {
    final notifier = _notifier(player: () => Completer<PlayerModel?>().future);

    unawaited(notifier.load());

    expect(notifier.teamStatus, SummaryStatus.loading);
    expect(notifier.statsStatus, SummaryStatus.loading);
  });

  test('un jugador con equipo muestra el equipo y los totales que suma el backend', () async {
    final statsService = _FakePlayerStatsService(() async => _anaTotals);
    final notifier = _notifier(player: () async => _ana, statsService: statsService);

    await notifier.load();

    expect(notifier.teamStatus, SummaryStatus.ready);
    expect(notifier.statsStatus, SummaryStatus.ready);
    expect(notifier.hasTeam, isTrue);
    expect(notifier.player?.teamName, 'Tigres');
    expect(notifier.totalStats?.matchesPlayed, 9);
    expect(notifier.totalStats?.goals, 3);
    expect(notifier.totalStats?.assists, 1);
    expect(notifier.totalStats?.yellowCards, 2);
    // Los totales se leen de una sola vez, sin recorrer los eventos del equipo.
    expect(statsService.mineCalls, 1);
  });

  test('un jugador sin partidos ni nada registrado tiene equipo pero no tiene total', () async {
    final notifier = _notifier(
      player: () async => _ana,
      totals: () async => const PlayerStatsModel(playerId: 'ana', teamId: ''),
    );

    await notifier.load();

    expect(notifier.statsStatus, SummaryStatus.ready);
    expect(notifier.totalStats, isNull);
  });

  test('un jugador que ya jugó partidos tiene total aunque no tenga goles ni tarjetas', () async {
    final notifier = _notifier(
      player: () async => _ana,
      totals: () async => const PlayerStatsModel(playerId: 'ana', teamId: '', matchesPlayed: 4),
    );

    await notifier.load();

    expect(notifier.totalStats?.matchesPlayed, 4);
  });

  test('sin equipo no se leen las estadísticas', () async {
    final statsService = _FakePlayerStatsService(() async => _anaTotals);
    final notifier = _notifier(
      player: () async => const PlayerModel(id: 'ana', firstName: 'Ana', lastName: '', email: 'ana@email.com'),
      statsService: statsService,
    );

    await notifier.load();

    expect(notifier.teamStatus, SummaryStatus.ready);
    expect(notifier.hasTeam, isFalse);
    expect(notifier.totalStats, isNull);
    expect(statsService.mineCalls, 0);
  });

  test('una cuenta que aún no tiene jugador queda sin equipo, no con error', () async {
    final notifier = _notifier(player: () async => null);

    await notifier.load();

    expect(notifier.teamStatus, SummaryStatus.ready);
    expect(notifier.player, isNull);
    expect(notifier.hasTeam, isFalse);
  });

  test('si fallan las estadísticas, el equipo se sigue mostrando', () async {
    final notifier = _notifier(
      player: () async => _ana,
      totals: () async => throw Exception('sin red'),
    );

    await notifier.load();

    expect(notifier.teamStatus, SummaryStatus.ready);
    expect(notifier.player?.id, 'ana');
    expect(notifier.statsStatus, SummaryStatus.failed);
    expect(notifier.totalStats, isNull);
  });

  test('si no se puede leer el jugador, fallan los dos bloques y reintentar los recupera', () async {
    var fail = true;
    final notifier = _notifier(
      player: () async {
        if (fail) throw Exception('sin red');
        return _ana;
      },
    );

    await notifier.load();

    expect(notifier.teamStatus, SummaryStatus.failed);
    expect(notifier.statsStatus, SummaryStatus.failed);

    fail = false;
    await notifier.load();

    expect(notifier.teamStatus, SummaryStatus.ready);
    expect(notifier.statsStatus, SummaryStatus.ready);
    expect(notifier.player?.id, 'ana');
  });

  test('la respuesta de una lectura vieja no pisa a la más nueva', () async {
    final slowFirst = Completer<PlayerModel?>();
    var calls = 0;
    final notifier = _notifier(
      player: () => calls++ == 0
          ? slowFirst.future
          : Future.value(const PlayerModel(id: 'nueva', firstName: 'N', lastName: '', email: 'n@email.com')),
    );

    final firstLoad = notifier.load();
    await notifier.load();
    slowFirst.complete(_ana);
    await firstLoad;

    expect(notifier.player?.id, 'nueva');
  });

  test('reemplazar al jugador (p. ej. con su foto nueva) avisa sin volver a leer', () async {
    final statsService = _FakePlayerStatsService(() async => _anaTotals);
    final notifier = _notifier(player: () async => _ana, statsService: statsService);
    await notifier.load();
    var notifications = 0;
    notifier.addListener(() => notifications++);

    notifier.replacePlayer(_ana.copyWith(profilePhotoUrl: 'players/ana/photo?v=1'));

    expect(notifier.player?.profilePhotoUrl, 'players/ana/photo?v=1');
    expect(notifications, 1);
    expect(statsService.mineCalls, 1);
  });

  test('una lectura que termina después de cerrar la pantalla no avisa a nadie', () async {
    final pending = Completer<PlayerModel?>();
    final notifier = _notifier(player: () => pending.future);

    final load = notifier.load();
    notifier.dispose();
    pending.complete(_ana);

    await expectLater(load, completes);
  });
}
