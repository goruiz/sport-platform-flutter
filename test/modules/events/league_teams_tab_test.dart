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

Widget _teamsTab({required bool isOwner, required List<TeamEventModel> managedTeams}) => Scaffold(
      body: LeagueTeamsTab(
        teams: [_team],
        isLoading: false,
        error: null,
        isOwner: isOwner,
        onRetry: () {},
        onManagePlayers: managedTeams.add,
      ),
    );

void main() {
  setUpAll(initRealTranslations);

  testWidgets('un jugador no ve el botón de plantilla ni puede abrirla tocando la tarjeta', (tester) async {
    final managedTeams = <TeamEventModel>[];

    await pumpWithRealTranslations(
      tester,
      home: (_) => _teamsTab(isOwner: false, managedTeams: managedTeams),
    );

    expect(find.text(_teamName), findsOneWidget);
    expect(find.byIcon(Icons.manage_accounts_outlined), findsNothing);

    await tester.tap(find.text(_teamName));
    await tester.pump();

    expect(managedTeams, isEmpty);
  });

  testWidgets('quien gestiona el evento ve el botón y abre la plantilla del equipo', (tester) async {
    final managedTeams = <TeamEventModel>[];

    await pumpWithRealTranslations(
      tester,
      home: (_) => _teamsTab(isOwner: true, managedTeams: managedTeams),
    );

    expect(find.byIcon(Icons.manage_accounts_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.manage_accounts_outlined));
    await tester.pump();

    expect(managedTeams, [_team]);
  });
}
