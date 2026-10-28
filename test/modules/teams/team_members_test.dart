import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/teams/domain/team_members.dart';

PlayerModel _player(String id, {bool isCaptain = false}) => PlayerModel(
      id: id,
      firstName: id,
      lastName: '',
      email: '$id@email.com',
      isCaptain: isCaptain,
    );

void main() {
  group('PlayerModel.fromJson', () {
    test('lee si es el capitán de su equipo', () {
      final player = PlayerModel.fromJson({'id': 'p1', 'isCaptain': true});

      expect(player.isCaptain, isTrue);
    });

    test('un backend que aún no manda el campo, o lo manda en falso, no lo hace capitán', () {
      expect(PlayerModel.fromJson({'id': 'p1'}).isCaptain, isFalse);
      expect(PlayerModel.fromJson({'id': 'p1', 'isCaptain': false}).isCaptain, isFalse);
    });
  });

  group('sortCaptainFirst', () {
    test('pone al capitán primero y deja a los demás en el mismo orden', () {
      final members = [_player('ana'), _player('beto'), _player('carla', isCaptain: true), _player('dani')];

      expect(sortCaptainFirst(members).map((member) => member.id), ['carla', 'ana', 'beto', 'dani']);
    });

    test('sin capitán no cambia el orden, y no modifica la lista recibida', () {
      final members = [_player('ana'), _player('beto')];

      expect(sortCaptainFirst(members).map((member) => member.id), ['ana', 'beto']);
      expect(members.map((member) => member.id), ['ana', 'beto']);
    });
  });
}
