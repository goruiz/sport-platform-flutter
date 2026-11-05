import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/team_model.dart';
import 'package:sport_platform/modules/home/data/datasource/home_dashboard_service.dart';

import '../../support/builders.dart';

/// El inicio ya no baja todos los equipos y eventos solo para rotular: toma los nombres de su propio equipo y de lo que
/// el backend puso en cada partido.
void main() {
  final matches = [
    matchOf(
      date: DateTime(2026, 11, 5),
      homeTeamName: 'Tigres',
      awayTeamName: 'Leones',
      eventName: 'Liga de barrio',
    ),
  ];

  test('toma el nombre de un equipo del propio partido', () {
    final data = HomeDashboardData(events: const [], matches: matches, teams: const [], currentPlayer: null);

    expect(data.teamName('home'), 'Tigres');
    expect(data.teamName('away'), 'Leones');
    expect(data.eventName('event-1'), 'Liga de barrio');
  });

  test('su propio equipo gana sobre el nombre que traiga el partido', () {
    final data = HomeDashboardData(
      events: const [],
      matches: matches,
      teams: const [TeamModel(id: 'home', name: 'Tigres FC')],
      currentPlayer: null,
    );

    expect(data.teamName('home'), 'Tigres FC');
  });

  test('un equipo o evento que no ve queda con un guion o vacío', () {
    final data = HomeDashboardData(events: const [], matches: matches, teams: const [], currentPlayer: null);

    expect(data.teamName('desconocido'), '—');
    expect(data.eventName('otro'), '');
  });

  test('un partido sin nombres no inventa ninguno', () {
    final unnamed = [matchOf(date: DateTime(2026, 11, 5))];
    final data = HomeDashboardData(events: const [], matches: unnamed, teams: const [], currentPlayer: null);

    expect(data.teamName('home'), '—');
  });
}
