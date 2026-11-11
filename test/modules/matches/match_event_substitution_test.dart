import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/matches/data/models/match_event_model.dart';
import 'package:sport_platform/modules/matches/domain/enums/match_event_type.dart';
import 'package:sport_platform/modules/matches/presentation/widgets/match_event_tile.dart';

import '../../support/real_translations.dart';

void main() {
  setUpAll(initRealTranslations);

  group('MatchEventModel: un cambio dice quién entra y quién sale', () {
    test('lee a quien sale además de a quien entra', () {
      final event = MatchEventModel.fromJson({
        'id': 'e1',
        'matchId': 'm1',
        'playerId': 'p2',
        'playerName': 'Luis Mora',
        'replacedPlayerId': 'p1',
        'replacedPlayerName': 'Ana Lopez',
        'teamId': 't1',
        'eventType': 'SUBSTITUTION',
        'minute': 60,
      });

      expect(event.type, MatchEventType.substitution);
      expect(event.isSubstitution, isTrue);
      expect(event.playerName, 'Luis Mora');
      expect(event.replacedPlayerName, 'Ana Lopez');
    });

    test('las demás líneas no son cambios y no traen a nadie que salga', () {
      final event = MatchEventModel.fromJson({'id': 'e1', 'eventType': 'GOAL', 'playerName': 'Ana Lopez'});

      expect(event.isSubstitution, isFalse);
      expect(event.replacedPlayerName, isNull);
    });

    test('el tipo se reconoce por el valor del backend', () {
      expect(MatchEventType.fromApi('SUBSTITUTION'), MatchEventType.substitution);
    });
  });

  group('MatchEventTile', () {
    Future<void> pumpTile(WidgetTester tester, MatchEventModel event) {
      return pumpWithRealTranslations(
        tester,
        home: (_) => Scaffold(body: MatchEventTile(event: event, teamName: 'Tigres')),
      );
    }

    testWidgets('un cambio se lee «Entra X · Sale Y»', (tester) async {
      await pumpTile(
        tester,
        MatchEventModel.fromJson({
          'id': 'e1',
          'playerName': 'Luis Mora',
          'replacedPlayerName': 'Ana Lopez',
          'teamId': 't1',
          'eventType': 'SUBSTITUTION',
          'minute': 60,
        }),
      );

      expect(find.text('Entra Luis Mora · Sale Ana Lopez'), findsOneWidget);
    });

    testWidgets('un cambio cuyo jugador que sale se borró no rompe: dice «jugador desconocido»', (tester) async {
      await pumpTile(
        tester,
        MatchEventModel.fromJson({
          'id': 'e1',
          'playerName': 'Luis Mora',
          'teamId': 't1',
          'eventType': 'SUBSTITUTION',
        }),
      );

      expect(find.textContaining('Entra Luis Mora · Sale '), findsOneWidget);
    });

    testWidgets('un gol sigue mostrando solo a su jugador', (tester) async {
      await pumpTile(
        tester,
        MatchEventModel.fromJson({'id': 'e1', 'playerName': 'Ana Lopez', 'teamId': 't1', 'eventType': 'GOAL', 'minute': 23}),
      );

      expect(find.text('Ana Lopez'), findsOneWidget);
    });
  });
}
