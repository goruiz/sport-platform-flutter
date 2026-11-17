import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/core/network/json_reader.dart';
import 'package:sport_platform/modules/matches/data/models/match_model.dart';
import 'package:sport_platform/modules/matches/presentation/widgets/match_scoreboard.dart';
import 'package:sport_platform/modules/matches/presentation/widgets/match_summary_card.dart';
import 'package:sport_platform/shared/enums/match_status.dart';

/// Lo que el backend siempre manda de un partido.
const _matchJson = {
  'id': 'm1',
  'homeTeamId': 'home',
  'awayTeamId': 'away',
  'matchDate': '2026-11-11T18:30:00',
  'status': 'SCHEDULED',
  'createdAt': '2026-11-01T09:00:00',
};

void main() {
  group('MatchModel.fromJson', () {
    test('lee lo obligatorio y deja en null lo que el backend no manda', () {
      final match = MatchModel.fromJson(_matchJson);

      expect(match.id, 'm1');
      expect(match.matchDate, DateTime(2026, 11, 11, 18, 30));
      expect(match.status, MatchStatus.scheduled);
      expect(match.eventId, isNull);
      expect(match.endsAt, isNull);
      expect(match.homeScore, isNull);
      expect(match.hasScore, isFalse);
    });

    test('un partido sin fecha no se inventa «ahora»: es una respuesta mal formada', () {
      final json = {..._matchJson}..remove('matchDate');

      expect(
        () => MatchModel.fromJson(json),
        throwsA(isA<MalformedResponseException>().having((e) => e.field, 'campo', 'matchDate')),
      );
    });

    test('un partido sin id ni equipos tampoco se completa con textos vacíos', () {
      for (final field in ['id', 'homeTeamId', 'awayTeamId', 'createdAt']) {
        final json = {..._matchJson}..remove(field);

        expect(() => MatchModel.fromJson(json), throwsA(isA<MalformedResponseException>()), reason: field);
      }
    });

    test('un partido de un evento guarda su id', () {
      expect(MatchModel.fromJson({..._matchJson, 'eventId': 'e1'}).eventId, 'e1');
    });
  });

  group('MatchStatus', () {
    test('cada estado se reconoce por el texto del backend, sin importar las mayúsculas', () {
      for (final status in MatchStatus.values.where((s) => s != MatchStatus.unknown)) {
        expect(MatchStatus.fromApi(status.apiValue), status);
      }
      expect(MatchStatus.fromApi('in_progress'), MatchStatus.inProgress);
    });

    test('un estado que la app no conoce, o que falta, es «desconocido» y no «Programado»', () {
      expect(MatchStatus.fromApi('REPROGRAMADO_POR_LLUVIA'), MatchStatus.unknown);
      expect(MatchStatus.fromApi(null), MatchStatus.unknown);
      expect(MatchModel.fromJson({..._matchJson, 'status': 'NUEVO'}).status, MatchStatus.unknown);
    });

    test('un partido desconocido enseña su estado en vez de esconderlo como uno normal', () {
      expect(MatchSummaryCard.shouldShowStatus(MatchStatus.unknown), isTrue);
      expect(MatchScoreboard.hasFirmSchedule(MatchStatus.unknown), isTrue);
    });
  });
}
