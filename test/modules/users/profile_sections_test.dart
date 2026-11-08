import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/rankings/data/models/player_stats_model.dart';
import 'package:sport_platform/modules/users/presentation/providers/profile_summary_notifier.dart';
import 'package:sport_platform/modules/users/presentation/widgets/profile_stats_section.dart';
import 'package:sport_platform/modules/users/presentation/widgets/profile_team_section.dart';
import 'package:sport_platform/shared/widgets/skeleton_box.dart';

import '../../support/real_translations.dart';

PlayerModel _player({bool isCaptain = false, String? teamId = 't1'}) => PlayerModel(
  id: 'ana',
  firstName: 'Ana',
  lastName: 'Pérez',
  email: 'ana@email.com',
  teamId: teamId,
  teamName: teamId == null ? null : 'Los Tigres',
  isCaptain: isCaptain,
);

Widget _teamSection(SummaryStatus status, PlayerModel? player, {VoidCallback? onRetry}) =>
    Scaffold(body: ProfileTeamSection(status: status, player: player, onRetry: onRetry ?? () {}));

Widget _statsSection(SummaryStatus status, PlayerStatsModel? stats, {VoidCallback? onRetry}) =>
    Scaffold(body: SingleChildScrollView(child: ProfileStatsSection(status: status, stats: stats, onRetry: onRetry ?? () {})));

void main() {
  setUpAll(initRealTranslations);

  group('ProfileTeamSection', () {
    testWidgets('muestra el equipo del jugador y su rol', (tester) async {
      await pumpWithRealTranslations(tester, home: (_) => _teamSection(SummaryStatus.ready, _player()));

      expect(find.text('MI EQUIPO'), findsOneWidget);
      expect(find.text('Los Tigres'), findsOneWidget);
      expect(find.text('Jugador'), findsOneWidget);
      expect(find.text('Capitán'), findsNothing);
    });

    testWidgets('al capitán lo dice como su rol', (tester) async {
      await pumpWithRealTranslations(tester, home: (_) => _teamSection(SummaryStatus.ready, _player(isCaptain: true)));

      expect(find.text('Capitán'), findsOneWidget);
      expect(find.text('Jugador'), findsNothing);
    });

    testWidgets('sin equipo lo dice, y una cuenta sin jugador también', (tester) async {
      await pumpWithRealTranslations(tester, home: (_) => _teamSection(SummaryStatus.ready, _player(teamId: null)));
      expect(find.text('Aún no perteneces a un equipo'), findsOneWidget);

      await pumpWithRealTranslations(tester, home: (_) => _teamSection(SummaryStatus.ready, null));
      expect(find.text('Aún no perteneces a un equipo'), findsOneWidget);
    });

    testWidgets('si falla ofrece reintentar', (tester) async {
      var retries = 0;
      await pumpWithRealTranslations(
        tester,
        home: (_) => _teamSection(SummaryStatus.failed, null, onRetry: () => retries++),
      );

      expect(find.text('No se pudo cargar tu equipo.'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));

      expect(retries, 1);
    });

    testWidgets('mientras carga muestra un esqueleto, no datos', (tester) async {
      await pumpWithRealTranslations(tester, home: (_) => _teamSection(SummaryStatus.loading, null));

      expect(find.byType(SkeletonBox), findsOneWidget);
      expect(find.text('Los Tigres'), findsNothing);
    });
  });

  group('ProfileStatsSection', () {
    const totals = PlayerStatsModel(
      playerId: 'ana',
      teamId: 't1',
      goals: 7,
      assists: 4,
      yellowCards: 2,
      redCards: 1,
      fouls: 9,
    );

    testWidgets('muestra los totales con la aclaración de que suman todos los eventos del equipo', (tester) async {
      await pumpWithRealTranslations(tester, home: (_) => _statsSection(SummaryStatus.ready, totals));

      expect(find.text('Mis estadísticas'), findsOneWidget);
      expect(find.text('Suma de todos los eventos de tu equipo'), findsOneWidget);
      for (final value in ['7', '4', '2', '1', '9']) {
        expect(find.text(value), findsOneWidget, reason: 'falta el contador $value');
      }
    });

    testWidgets('sin nada registrado lo explica', (tester) async {
      await pumpWithRealTranslations(tester, home: (_) => _statsSection(SummaryStatus.ready, null));

      expect(find.text('Aún no tienes goles, asistencias, tarjetas ni faltas registrados.'), findsOneWidget);
    });

    testWidgets('si falla ofrece reintentar', (tester) async {
      var retries = 0;
      await pumpWithRealTranslations(
        tester,
        home: (_) => _statsSection(SummaryStatus.failed, null, onRetry: () => retries++),
      );

      expect(find.text('No se pudieron cargar tus estadísticas.'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));

      expect(retries, 1);
    });

    testWidgets('mientras carga muestra un esqueleto', (tester) async {
      await pumpWithRealTranslations(tester, home: (_) => _statsSection(SummaryStatus.loading, null));

      expect(find.byType(SkeletonBox), findsOneWidget);
    });
  });
}
