import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/courts/data/models/court_availability_model.dart';
import 'package:sport_platform/modules/courts/presentation/widgets/court_schedule_section.dart';
import 'package:sport_platform/modules/matches/data/models/match_attendance_model.dart';
import 'package:sport_platform/modules/matches/presentation/widgets/match_attendance_card.dart';
import 'package:sport_platform/modules/reports/domain/team_report.dart';
import 'package:sport_platform/modules/reports/presentation/widgets/team_stats_card.dart';
import 'package:sport_platform/modules/users/presentation/widgets/profile_avatar.dart';
import 'package:sport_platform/shared/enums/summary_status.dart';

import '../support/real_translations.dart';

/// Una clave de traducción sin resolver se ve como ella misma: letras y puntos, sin espacios.
final _unresolvedKey = RegExp(r'^[a-z_]+(\.[a-z_]+)+$');

/// Los textos en pantalla que son una clave sin traducir.
List<String> _unresolvedTexts(WidgetTester tester) => [
      for (final text in tester.widgetList<Text>(find.byType(Text)))
        if (text.data != null && _unresolvedKey.hasMatch(text.data!)) text.data!,
    ];

final _availability = CourtAvailabilityModel(
  courtId: 'c1',
  date: DateTime(2026, 11, 10),
  opensAt: '08:00',
  closesAt: '22:00',
  busySlots: [
    CourtBusySlot(
      startsAt: DateTime(2026, 11, 10, 16),
      endsAt: DateTime(2026, 11, 10, 18),
      matchId: 'm1',
      homeTeamName: 'Tigres',
      awayTeamName: 'Halcones',
    ),
  ],
  freeSlots: [
    CourtTimeSlot(startsAt: DateTime(2026, 11, 10, 8), endsAt: DateTime(2026, 11, 10, 16)),
    CourtTimeSlot(startsAt: DateTime(2026, 11, 10, 18), endsAt: DateTime(2026, 11, 10, 22)),
  ],
);

Widget _schedule(SummaryStatus status, {CourtAvailabilityModel? availability}) => Scaffold(
      body: SingleChildScrollView(
        child: CourtScheduleSection(
          days: [DateTime(2026, 11, 9), DateTime(2026, 11, 10)],
          selectedDay: DateTime(2026, 11, 10),
          status: status,
          availability: availability,
          onDaySelected: (_) {},
          onRetry: () {},
        ),
      ),
    );

Widget _attendanceCard({required bool canAnswer, AttendanceStatus? mine}) => Scaffold(
      body: SingleChildScrollView(
        child: MatchAttendanceCard(
          attendance: MatchAttendanceModel(
            matchId: 'm1',
            myStatus: mine,
            attendees: const [
              MatchAttendee(playerId: '1', playerName: 'Ana', teamId: 'home', status: AttendanceStatus.confirmed),
              MatchAttendee(playerId: '2', playerName: 'Luis', teamId: 'home', status: AttendanceStatus.declined),
              MatchAttendee(playerId: '3', playerName: 'Rival', teamId: 'away', status: AttendanceStatus.confirmed),
            ],
          ),
          myTeamId: 'home',
          canAnswer: canAnswer,
          isSaving: false,
          onAnswer: (_) {},
          onClearAnswer: () {},
        ),
      ),
    );

void main() {
  setUpAll(initRealTranslations);

  group('horarios de una cancha', () {
    testWidgets('muestra los tramos libres y el partido que ocupa la cancha', (tester) async {
      await pumpWithRealTranslations(
        tester,
        home: (_) => _schedule(SummaryStatus.ready, availability: _availability),
      );

      expect(find.text('Abierta de 08:00 a 22:00'), findsOneWidget);
      expect(find.text('08:00 – 16:00'), findsOneWidget);
      expect(find.text('Libre · 8 h'), findsOneWidget);
      expect(find.text('Tigres – Halcones'), findsOneWidget);
    });

    testWidgets('si falló la lectura lo dice y ofrece reintentar', (tester) async {
      await pumpWithRealTranslations(tester, home: (_) => _schedule(SummaryStatus.failed));

      expect(find.text('No se pudieron cargar los horarios.'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });

  group('asistencia al partido', () {
    testWidgets('con respuesta abierta ofrece los dos botones y lista solo a los de su equipo', (tester) async {
      await pumpWithRealTranslations(tester, home: (_) => _attendanceCard(canAnswer: true));

      expect(find.text('Voy'), findsOneWidget);
      expect(find.text('No puedo ir'), findsOneWidget);
      expect(find.text('Confirmados: 1 · No asistirán: 1'), findsOneWidget);
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Luis'), findsOneWidget);
      expect(find.text('Rival'), findsNothing);
    });

    testWidgets('cerrada no ofrece botones y recuerda lo que respondió', (tester) async {
      await pumpWithRealTranslations(
        tester,
        home: (_) => _attendanceCard(canAnswer: false, mine: AttendanceStatus.confirmed),
      );

      expect(find.text('Voy'), findsNothing);
      expect(find.text('Confirmaste que irás al partido.'), findsOneWidget);
    });
  });

  group('en cada idioma ninguna clave queda sin traducir', () {
    for (final locale in supportedTestLocales) {
      testWidgets('horarios de una cancha (${locale.languageCode})', (tester) async {
        await pumpWithRealTranslations(
          tester,
          locale: locale,
          home: (_) => _schedule(SummaryStatus.ready, availability: _availability),
        );

        expect(_unresolvedTexts(tester), isEmpty);
      });

      testWidgets('error de horarios (${locale.languageCode})', (tester) async {
        await pumpWithRealTranslations(tester, locale: locale, home: (_) => _schedule(SummaryStatus.failed));

        expect(_unresolvedTexts(tester), isEmpty);
      });

      testWidgets('asistencia al partido (${locale.languageCode})', (tester) async {
        await pumpWithRealTranslations(
          tester,
          locale: locale,
          home: (_) => _attendanceCard(canAnswer: true, mine: AttendanceStatus.declined),
        );

        expect(_unresolvedTexts(tester), isEmpty);
      });

      testWidgets('asistencia cerrada (${locale.languageCode})', (tester) async {
        await pumpWithRealTranslations(tester, locale: locale, home: (_) => _attendanceCard(canAnswer: false));

        expect(_unresolvedTexts(tester), isEmpty);
      });

      testWidgets('participación y disciplina del equipo (${locale.languageCode})', (tester) async {
        await pumpWithRealTranslations(
          tester,
          locale: locale,
          home: (_) => const Scaffold(
            body: TeamStatsCard(
              eventsPlayed: 2,
              disciplineStatus: SummaryStatus.failed,
              discipline: TeamDiscipline(),
            ),
          ),
        );

        expect(_unresolvedTexts(tester), isEmpty);
      });

      testWidgets('foto de perfil (${locale.languageCode})', (tester) async {
        await pumpWithRealTranslations(
          tester,
          locale: locale,
          home: (_) => Scaffold(body: ProfileAvatar(name: 'Ana Pérez', onTap: () {})),
        );

        expect(_unresolvedTexts(tester), isEmpty);
      });
    }
  });
}
