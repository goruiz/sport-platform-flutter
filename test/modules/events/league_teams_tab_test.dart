import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/team_event_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/widgets/league_teams_tab.dart';

import '../../support/real_translations.dart';

const _teamName = 'Los Tigres';

final _team = TeamEventModel(
  id: 'registration-1',
  teamId: 'team-1',
  teamName: _teamName,
  eventId: 'event-1',
  createdAt: DateTime(2026, 10, 1),
);

Widget _teamsTab({required List<TeamEventModel> openedTeams, bool canOpen = true}) => Scaffold(
      body: LeagueTeamsTab(
        teams: [_team],
        isLoading: false,
        error: null,
        onRetry: () {},
        onOpen: canOpen ? openedTeams.add : null,
      ),
    );

void main() {
  setUpAll(initRealTranslations);

  testWidgets('el jugador solo ve el equipo: sin botones de plantilla ni de quitarlo del evento', (tester) async {
    await pumpWithRealTranslations(tester, home: (_) => _teamsTab(openedTeams: []));

    expect(find.text(_teamName), findsOneWidget);
    expect(find.byIcon(Icons.manage_accounts_outlined), findsNothing);
    expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
  });

  testWidgets('tocar la tarjeta abre el detalle del equipo en el evento', (tester) async {
    final openedTeams = <TeamEventModel>[];

    await pumpWithRealTranslations(tester, home: (_) => _teamsTab(openedTeams: openedTeams));

    expect(find.byIcon(Icons.chevron_right), findsOneWidget);

    await tester.tap(find.text(_teamName));
    await tester.pump();

    expect(openedTeams, [_team]);
  });

  testWidgets('sin detalle al que ir la tarjeta no se ofrece como tocable', (tester) async {
    await pumpWithRealTranslations(tester, home: (_) => _teamsTab(openedTeams: [], canOpen: false));

    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });
}
