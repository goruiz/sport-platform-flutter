import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/teams/presentation/providers/active_team_notifier.dart';

const _storageKey = 'active_team_id';

PlayerModel _playerIn(List<String> teamIds) => PlayerModel(
      id: 'ana',
      firstName: 'Ana',
      lastName: 'Pérez',
      email: 'ana@email.com',
      teams: [for (final id in teamIds) PlayerTeam(teamId: id, teamName: 'Equipo $id')],
    );

Future<String?> _storedTeamId() async => (await SharedPreferences.getInstance()).getString(_storageKey);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('sync', () {
    test('mientras no haya elegido, el activo es el último al que entró (el primero de la lista)', () async {
      final notifier = ActiveTeamNotifier();

      final active = await notifier.sync(_playerIn(['tigres', 'pumas']));

      expect(active?.teamId, 'tigres');
      expect(notifier.activeTeamId, 'tigres');
      expect(notifier.teams.map((team) => team.teamId), ['tigres', 'pumas']);
      expect(notifier.hasSeveralTeams, isTrue);
    });

    test('sin jugador o sin equipos no hay equipo activo', () async {
      final notifier = ActiveTeamNotifier();

      expect(await notifier.sync(null), isNull);
      expect(await notifier.sync(_playerIn([])), isNull);
      expect(notifier.activeTeamId, isNull);
      expect(notifier.hasSeveralTeams, isFalse);
    });

    test('con un backend anterior, que solo manda teamId, ese es el equipo', () async {
      final notifier = ActiveTeamNotifier();
      const legacy = PlayerModel(id: 'ana', firstName: 'Ana', lastName: 'Pérez', email: 'a@e.com', teamId: 'solo', teamName: 'Solo');

      expect((await notifier.sync(legacy))?.teamId, 'solo');
    });

    test('conserva el equipo elegido cuando se vuelve a leer al jugador', () async {
      final notifier = ActiveTeamNotifier();
      await notifier.sync(_playerIn(['tigres', 'pumas']));
      notifier.select('pumas');

      final active = await notifier.sync(_playerIn(['tigres', 'pumas']));

      expect(active?.teamId, 'pumas');
    });

    test('si abandonó el activo, pasa a serlo el que ocupa ahora su lugar', () async {
      final notifier = ActiveTeamNotifier();
      await notifier.sync(_playerIn(['tigres', 'pumas', 'osos']));
      notifier.select('pumas');

      final active = await notifier.sync(_playerIn(['tigres', 'osos']));

      expect(active?.teamId, 'osos');
    });

    test('si abandonó el último de la lista, queda en el nuevo último', () async {
      final notifier = ActiveTeamNotifier();
      await notifier.sync(_playerIn(['tigres', 'pumas']));
      notifier.select('pumas');

      expect((await notifier.sync(_playerIn(['tigres'])))?.teamId, 'tigres');
    });

    test('un equipo guardado que ya no es del jugador se ignora', () async {
      SharedPreferences.setMockInitialValues({_storageKey: 'que-dejo'});
      final notifier = ActiveTeamNotifier();

      expect((await notifier.sync(_playerIn(['tigres', 'pumas'])))?.teamId, 'tigres');
    });
  });

  group('persistencia', () {
    test('abre en el equipo que el jugador eligió la última vez', () async {
      SharedPreferences.setMockInitialValues({_storageKey: 'pumas'});
      final notifier = ActiveTeamNotifier();

      expect((await notifier.sync(_playerIn(['tigres', 'pumas'])))?.teamId, 'pumas');
    });

    test('elegir un equipo lo guarda en el dispositivo', () async {
      final notifier = ActiveTeamNotifier();
      await notifier.sync(_playerIn(['tigres', 'pumas']));

      notifier.select('pumas');
      await pumpEventQueue();

      expect(await _storedTeamId(), 'pumas');
    });

    test('al cerrar la sesión se olvida todo, también lo guardado', () async {
      final notifier = ActiveTeamNotifier();
      await notifier.sync(_playerIn(['tigres', 'pumas']));
      notifier.select('pumas');
      await pumpEventQueue();

      notifier.clear();
      await pumpEventQueue();

      expect(notifier.activeTeamId, isNull);
      expect(notifier.teams, isEmpty);
      expect(await _storedTeamId(), isNull);
    });
  });

  group('select', () {
    test('cambia el equipo activo y avisa', () async {
      final notifier = ActiveTeamNotifier();
      await notifier.sync(_playerIn(['tigres', 'pumas']));
      var notifications = 0;
      notifier.addListener(() => notifications++);

      notifier.select('pumas');

      expect(notifier.activeTeamId, 'pumas');
      expect(notifier.activeTeam?.teamName, 'Equipo pumas');
      expect(notifications, 1);
    });

    test('elegir el que ya es el activo, o uno que no es suyo, no cambia nada ni avisa', () async {
      final notifier = ActiveTeamNotifier();
      await notifier.sync(_playerIn(['tigres', 'pumas']));
      var notifications = 0;
      notifier.addListener(() => notifications++);

      notifier.select('tigres');
      notifier.select('ajeno');

      expect(notifier.activeTeamId, 'tigres');
      expect(notifications, 0);
    });
  });

  group('avisos', () {
    test('la primera lectura no avisa: nadie había visto otro equipo', () async {
      final notifier = ActiveTeamNotifier();
      var changedActive = 0;
      notifier.addListener(() => changedActive++);

      await notifier.sync(_playerIn(['tigres', 'pumas']));

      // Cambia la lista de equipos (de nada a dos), y eso sí se avisa para que el selector la muestre…
      expect(changedActive, 1);
      // …pero el equipo activo nunca pasó de uno a otro.
      expect(notifier.activeTeamId, 'tigres');
    });

    test('si cambia la lista pero no el equipo activo, quien depende del activo lo ve igual', () async {
      final notifier = ActiveTeamNotifier();
      await notifier.sync(_playerIn(['tigres', 'pumas']));
      final seenActiveTeamIds = <String?>[];
      notifier.addListener(() => seenActiveTeamIds.add(notifier.activeTeamId));

      await notifier.sync(_playerIn(['tigres', 'pumas', 'osos']));

      expect(seenActiveTeamIds, ['tigres']);
    });

    test('leer lo mismo otra vez no avisa', () async {
      final notifier = ActiveTeamNotifier();
      await notifier.sync(_playerIn(['tigres', 'pumas']));
      var notifications = 0;
      notifier.addListener(() => notifications++);

      await notifier.sync(_playerIn(['tigres', 'pumas']));

      expect(notifications, 0);
    });

    test('si abandona el activo, avisa con el nuevo equipo activo', () async {
      final notifier = ActiveTeamNotifier();
      await notifier.sync(_playerIn(['tigres', 'pumas']));
      final seenActiveTeamIds = <String?>[];
      notifier.addListener(() => seenActiveTeamIds.add(notifier.activeTeamId));

      await notifier.sync(_playerIn(['pumas']));

      expect(seenActiveTeamIds, ['pumas']);
    });
  });
}
