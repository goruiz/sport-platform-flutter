import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_format_rules.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/event_format_structure.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/tiebreaker_criterion.dart';
import 'package:sport_platform/modules/events/shared/presentation/widgets/event_rules_card.dart';
import 'package:sport_platform/shared/widgets/app_card.dart';

import '../../../support/real_translations.dart';

EventModel _event({EventFormatRules? rules, int? minPlayers, int? maxPlayers}) => EventModel(
  id: 'event-1',
  name: 'Liga',
  format: '',
  status: 'ACTIVE',
  startDate: DateTime(2026, 10, 1),
  endDate: DateTime(2026, 12, 1),
  createdAt: DateTime(2026, 1, 1),
  formatRules: rules,
  minPlayersPerTeam: minPlayers,
  maxPlayersPerTeam: maxPlayers,
);

const _league = EventFormatRules(
  structure: EventFormatStructure.roundRobin,
  roundTrip: true,
  pointsForWin: 3,
  pointsForDraw: 1,
  pointsForLoss: 0,
  tiebreakers: [TiebreakerCriterion.goalDifference, TiebreakerCriterion.goalsFor],
);

Widget _card(EventModel event) => Scaffold(body: SingleChildScrollView(child: EventRulesCard(event: event)));

/// Todo texto en pantalla, para comprobar que ninguna clave de traducción se coló sin traducir.
List<String> _allTexts(WidgetTester tester) => [
  for (final text in tester.widgetList<Text>(find.byType(Text)))
    if (text.data != null) text.data!,
];

void main() {
  setUpAll(initRealTranslations);

  testWidgets('cuenta las reglas del torneo en español', (tester) async {
    await pumpWithRealTranslations(
      tester,
      home: (_) => _card(_event(rules: _league, minPlayers: 5, maxPlayers: 12)),
    );

    expect(find.text('Reglas del torneo'), findsOneWidget);
    expect(find.text('Liga (todos contra todos)'), findsOneWidget);
    expect(find.text('Ida y vuelta'), findsOneWidget);
    expect(find.text('Victoria 3 · Empate 1 · Derrota 0'), findsOneWidget);
    expect(find.text('De 5 a 12'), findsOneWidget);
  });

  testWidgets('los desempates se numeran en su orden de prioridad', (tester) async {
    await pumpWithRealTranslations(tester, home: (_) => _card(_event(rules: _league)));

    expect(find.text('1. Diferencia de goles\n2. Goles a favor'), findsOneWidget);
  });

  testWidgets('una eliminatoria no muestra puntos ni desempates', (tester) async {
    await pumpWithRealTranslations(
      tester,
      home: (_) => _card(
        _event(
          rules: const EventFormatRules(
            structure: EventFormatStructure.knockout,
            knockoutRoundTrip: false,
            thirdPlaceMatch: true,
          ),
        ),
      ),
    );

    expect(find.text('Partido único'), findsOneWidget);
    expect(find.text('Puntos'), findsNothing);
    expect(find.text('Desempates'), findsNothing);
  });

  testWidgets('un evento sin reglas ni límites no dibuja la tarjeta', (tester) async {
    await pumpWithRealTranslations(tester, home: (_) => _card(_event()));

    expect(find.byType(AppCard), findsNothing);
    expect(find.text('Reglas del torneo'), findsNothing);
  });

  testWidgets('sin reglas de formato, los límites de jugadores igual se cuentan', (tester) async {
    await pumpWithRealTranslations(tester, home: (_) => _card(_event(minPlayers: 7, maxPlayers: 7)));

    expect(find.text('Jugadores por equipo'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
  });

  for (final locale in supportedTestLocales) {
    testWidgets('en ${locale.languageCode} ninguna clave queda sin traducir', (tester) async {
      await pumpWithRealTranslations(
        tester,
        locale: locale,
        home: (_) => _card(
          _event(
            rules: const EventFormatRules(
              structure: EventFormatStructure.groupsKnockout,
              roundTrip: true,
              pointsForWin: 3,
              pointsForDraw: 1,
              pointsForLoss: 0,
              tiebreakers: TiebreakerCriterion.values,
              groupCount: 4,
              teamsAdvancingPerGroup: 2,
              knockoutRoundTrip: false,
              thirdPlaceMatch: true,
              grandFinalReset: false,
            ),
            minPlayers: 5,
            maxPlayers: 12,
          ),
        ),
      );

      final texts = _allTexts(tester);
      expect(texts, isNotEmpty);
      for (final text in texts) {
        expect(text.contains('event_rules.'), isFalse, reason: 'clave sin traducir en ${locale.languageCode}: $text');
        expect(text.contains('championship.'), isFalse, reason: 'clave sin traducir en ${locale.languageCode}: $text');
        expect(text.contains('{}'), isFalse, reason: 'marcador sin rellenar en ${locale.languageCode}: $text');
      }
    });
  }
}
