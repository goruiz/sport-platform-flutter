import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/enums/match_status.dart';
import 'package:sport_platform/modules/matches/presentation/widgets/match_scoreboard.dart';
import 'package:sport_platform/modules/matches/presentation/widgets/match_summary_card.dart';

import '../../support/builders.dart';
import '../../support/real_translations.dart';

Widget _card(MatchModel match, {String eventName = 'Liga Norte', String? courtName}) => Scaffold(
      body: MatchSummaryCard(
        match: match,
        homeName: 'Los Halcones',
        awayName: 'Tigres',
        eventName: eventName,
        courtName: courtName,
        showDay: false,
      ),
    );

void main() {
  setUpAll(initRealTranslations);

  group('qué estado se rotula', () {
    test('un partido programado o jugado no repite su estado en cada tarjeta', () {
      expect(MatchSummaryCard.shouldShowStatus(MatchStatus.scheduled), isFalse);
      expect(MatchSummaryCard.shouldShowStatus(MatchStatus.finished), isFalse);
      expect(MatchSummaryCard.shouldShowStatus(MatchStatus.completed), isFalse);
    });

    test('lo fuera de lo normal sí se rotula', () {
      for (final status in [
        MatchStatus.inProgress,
        MatchStatus.postponed,
        MatchStatus.suspended,
        MatchStatus.cancelled,
        MatchStatus.rescheduled,
      ]) {
        expect(MatchSummaryCard.shouldShowStatus(status), isTrue, reason: '$status');
      }
    });

    test('solo un partido aplazado, suspendido o cancelado pierde su hora firme', () {
      expect(MatchScoreboard.hasFirmSchedule(MatchStatus.scheduled), isTrue);
      expect(MatchScoreboard.hasFirmSchedule(MatchStatus.inProgress), isTrue);
      expect(MatchScoreboard.hasFirmSchedule(MatchStatus.postponed), isFalse);
      expect(MatchScoreboard.hasFirmSchedule(MatchStatus.suspended), isFalse);
      expect(MatchScoreboard.hasFirmSchedule(MatchStatus.cancelled), isFalse);
    });
  });

  group('lo que dice la tarjeta', () {
    testWidgets('un partido por jugar enseña la hora y los dos equipos', (tester) async {
      final match = matchOf(date: DateTime(2026, 11, 8, 18, 30));

      await pumpWithRealTranslations(tester, home: (_) => _card(match, courtName: 'Cancha 1'));

      expect(find.text('18:30'), findsOneWidget);
      expect(find.text('Los Halcones'), findsOneWidget);
      expect(find.text('Tigres'), findsOneWidget);
      expect(find.text('Liga Norte'), findsOneWidget);
      expect(find.text('Cancha 1'), findsOneWidget);
      expect(find.text('Programado'), findsNothing);
    });

    testWidgets('un partido jugado enseña el marcador y no la hora', (tester) async {
      final match = matchOf(
        date: DateTime(2026, 11, 1, 18, 30),
        status: MatchStatus.finished,
        homeScore: 2,
        awayScore: 1,
      );

      await pumpWithRealTranslations(tester, home: (_) => _card(match));

      expect(find.text('2 – 1'), findsOneWidget);
      expect(find.text('18:30'), findsNothing);
    });

    testWidgets('un partido aplazado enseña «VS» y su estado en vez de una hora que ya no vale', (tester) async {
      final match = matchOf(date: DateTime(2026, 11, 8, 18, 30), status: MatchStatus.postponed);

      await pumpWithRealTranslations(tester, home: (_) => _card(match));

      expect(find.text('VS'), findsOneWidget);
      expect(find.text('18:30'), findsNothing);
      expect(find.text('Aplazado'), findsOneWidget);
    });

    testWidgets('sin nombre de evento ni cancha ni estado raro, la tarjeta es solo el marcador', (tester) async {
      final match = matchOf(date: DateTime(2026, 11, 8, 18, 30));

      await pumpWithRealTranslations(tester, home: (_) => _card(match, eventName: ''));

      expect(find.byIcon(Icons.emoji_events_outlined), findsNothing);
      expect(find.byIcon(Icons.location_on_outlined), findsNothing);
    });
  });
}
