import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/matches/data/models/match_dispute_model.dart';
import 'package:sport_platform/modules/matches/presentation/widgets/match_result_dispute_card.dart';
import 'package:sport_platform/modules/matches/presentation/widgets/match_result_dispute_sheet.dart';

import '../../support/builders.dart';
import '../../support/real_translations.dart';

MatchDisputeModel _dispute({
  DisputeStatus status = DisputeStatus.open,
  String? note,
  int? proposedHome,
  int? proposedAway,
}) {
  return MatchDisputeModel(
    id: 'd1',
    matchId: 'match-1',
    status: status,
    teamId: 'home',
    reason: 'El gol del minuto 80 no fue nuestro',
    proposedHomeScore: proposedHome,
    proposedAwayScore: proposedAway,
    createdAt: DateTime(2026, 11, 10),
    resolutionNote: note,
  );
}

Future<void> _pumpCard(
  WidgetTester tester, {
  List<MatchDisputeModel> disputes = const [],
  bool isSaving = false,
  VoidCallback? onReport,
}) {
  return pumpWithRealTranslations(
    tester,
    home: (_) => Scaffold(
      body: MatchResultDisputeCard(
        disputes: disputes,
        homeName: 'Leones',
        awayName: 'Tigres',
        isSaving: isSaving,
        onReport: onReport ?? () {},
      ),
    ),
  );
}

void main() {
  setUpAll(initRealTranslations);

  group('MatchResultDisputeCard', () {
    testWidgets('sin avisos pregunta, en palabras simples, si hay un problema y ofrece avisar', (tester) async {
      var reported = 0;
      await _pumpCard(tester, onReport: () => reported++);

      expect(find.text('¿Hay un problema con el resultado?'), findsOneWidget);
      expect(find.text('Avisar del problema'), findsOneWidget);

      await tester.tap(find.text('Avisar del problema'));
      expect(reported, 1);
    });

    testWidgets('un aviso esperando respuesta se ve y no deja mandar otro', (tester) async {
      await _pumpCard(tester, disputes: [_dispute(proposedHome: 2, proposedAway: 2)]);

      expect(find.text('Esperando respuesta del organizador'), findsOneWidget);
      expect(find.text('Tu aviso: El gol del minuto 80 no fue nuestro'), findsOneWidget);
      expect(find.text('Marcador que propones: Leones 2 – 2 Tigres'), findsOneWidget);
      expect(find.text('Avisar del problema'), findsNothing);
      expect(find.text('Avisar de otro problema'), findsNothing);
    });

    testWidgets('un aviso respondido muestra la respuesta y deja avisar de otro problema', (tester) async {
      await _pumpCard(
        tester,
        disputes: [_dispute(status: DisputeStatus.rejected, note: 'El acta del árbitro lo confirma')],
      );

      expect(find.text('El resultado se mantiene'), findsOneWidget);
      expect(find.text('Respuesta del organizador: El acta del árbitro lo confirma'), findsOneWidget);
      expect(find.text('Avisar de otro problema'), findsOneWidget);
    });

    testWidgets('mientras se envía, el botón no responde', (tester) async {
      var reported = 0;
      await _pumpCard(tester, isSaving: true, onReport: () => reported++);

      await tester.tap(find.text('Avisar del problema'));

      expect(reported, 0);
    });
  });

  group('MatchResultDisputeSheet', () {
    final match = matchOf(date: DateTime(2026, 11, 8), homeScore: 2, awayScore: 1);
    final received = <Map<String, Object?>>[];
    String? backendProblem;

    Future<String?> send({required String reason, int? proposedHomeScore, int? proposedAwayScore}) async {
      received.add({'reason': reason, 'home': proposedHomeScore, 'away': proposedAwayScore});
      return backendProblem;
    }

    setUp(() {
      received.clear();
      backendProblem = null;
    });

    Future<void> openSheet(WidgetTester tester) async {
      await pumpWithRealTranslations(
        tester,
        home: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => MatchResultDisputeSheet.show(
                context: context,
                match: match,
                homeName: 'Leones',
                awayName: 'Tigres',
                onSend: send,
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('muestra el resultado registrado y pide qué está mal', (tester) async {
      await openSheet(tester);

      expect(find.text('Cuéntanos qué pasó'), findsOneWidget);
      expect(find.text('Resultado registrado: Leones 2 – 1 Tigres'), findsOneWidget);
      expect(find.text('¿Qué está mal?'), findsOneWidget);
    });

    testWidgets('sin contar qué pasó no se envía nada', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Enviar aviso'));
      await tester.pumpAndSettle();

      expect(find.text('Cuéntanos qué está mal.'), findsOneWidget);
      expect(received, isEmpty);
    });

    testWidgets('el marcador a medias se avisa y no se envía', (tester) async {
      await openSheet(tester);
      await tester.enterText(find.byType(TextFormField).at(0), 'Falta un gol');
      await tester.enterText(find.byType(TextFormField).at(1), '2');

      await tester.tap(find.text('Enviar aviso'));
      await tester.pumpAndSettle();

      expect(find.text('Escribe los goles de los dos equipos, o deja las dos casillas vacías.'), findsOneWidget);
      expect(received, isEmpty);
    });

    testWidgets('solo con lo que pasó se envía sin marcador y se cierra', (tester) async {
      await openSheet(tester);
      await tester.enterText(find.byType(TextFormField).at(0), '  El gol no fue nuestro ');

      await tester.tap(find.text('Enviar aviso'));
      await tester.pumpAndSettle();

      expect(received, [
        {'reason': 'El gol no fue nuestro', 'home': null, 'away': null},
      ]);
      expect(find.text('Cuéntanos qué pasó'), findsNothing);
    });

    testWidgets('con el marcador correcto lo envía junto con lo que pasó', (tester) async {
      await openSheet(tester);
      await tester.enterText(find.byType(TextFormField).at(0), 'Falta un gol');
      await tester.enterText(find.byType(TextFormField).at(1), '3');
      await tester.enterText(find.byType(TextFormField).at(2), '1');

      await tester.tap(find.text('Enviar aviso'));
      await tester.pumpAndSettle();

      expect(received, [
        {'reason': 'Falta un gol', 'home': 3, 'away': 1},
      ]);
    });

    testWidgets('si el backend lo rechaza, dice por qué y deja corregir sin cerrar', (tester) async {
      backendProblem = 'match_detail.dispute.errors.WINDOW_CLOSED';
      await openSheet(tester);
      await tester.enterText(find.byType(TextFormField).at(0), 'Falta un gol');

      await tester.tap(find.text('Enviar aviso'));
      await tester.pumpAndSettle();

      expect(find.text('Ya pasó el tiempo para avisar de un problema con este resultado.'), findsOneWidget);
      expect(find.text('Cuéntanos qué pasó'), findsOneWidget);
    });
  });
}
