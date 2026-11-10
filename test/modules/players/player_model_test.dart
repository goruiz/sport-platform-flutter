import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';

void main() {
  group('PlayerModel.fromJson: un jugador puede jugar en varios equipos (uno por organización)', () {
    test('lee todos sus equipos, con la capitanía de cada uno', () {
      final player = PlayerModel.fromJson({
        'id': 'ana',
        'firstName': 'Ana',
        'lastName': 'Pérez',
        'email': 'ana@email.com',
        'teamId': 'b1',
        'teamName': 'Tigres',
        'isCaptain': false,
        'teams': [
          {'teamId': 'b1', 'teamName': 'Tigres', 'organizationId': 'org-b', 'isCaptain': false},
          {'teamId': 'a1', 'teamName': 'Leones', 'organizationId': 'org-a', 'isCaptain': true},
        ],
      });

      expect(player.allTeams.map((team) => team.teamName), ['Tigres', 'Leones']);
      expect(player.allTeams.map((team) => team.isCaptain), [false, true]);
      expect(player.allTeams.last.organizationId, 'org-a');
      expect(player.teamIds, {'b1', 'a1'});
      // El equipo de siempre (el último al que entró) sigue disponible para lo que lee uno solo.
      expect(player.teamId, 'b1');
    });

    test('con un backend anterior, que solo manda teamId, su único equipo es ese', () {
      final player = PlayerModel.fromJson({
        'id': 'ana',
        'email': 'ana@email.com',
        'teamId': 'a1',
        'teamName': 'Leones',
        'isCaptain': true,
      });

      expect(player.teams, isEmpty);
      expect(player.allTeams, hasLength(1));
      expect(player.allTeams.single.teamId, 'a1');
      expect(player.allTeams.single.teamName, 'Leones');
      expect(player.allTeams.single.isCaptain, isTrue);
      expect(player.teamIds, {'a1'});
    });

    test('sin equipo no tiene ninguno', () {
      final player = PlayerModel.fromJson({'id': 'ana', 'email': 'ana@email.com', 'teams': []});

      expect(player.allTeams, isEmpty);
      expect(player.teamIds, isEmpty);
    });

    test('una lista de equipos que no es una lista se ignora', () {
      final player = PlayerModel.fromJson({'id': 'ana', 'email': 'ana@email.com', 'teams': 'x'});

      expect(player.allTeams, isEmpty);
    });
  });

  test('toJson y copyWith conservan los equipos', () {
    final player = PlayerModel.fromJson({
      'id': 'ana',
      'email': 'ana@email.com',
      'teams': [
        {'teamId': 'a1', 'teamName': 'Leones', 'isCaptain': true},
      ],
    });

    final again = PlayerModel.fromJson(player.toJson());

    expect(again.allTeams.single.teamId, 'a1');
    expect(again.allTeams.single.isCaptain, isTrue);
    expect(player.copyWith(firstName: 'Ana').allTeams.single.teamId, 'a1');
  });
}
