import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';

/// Cliente que no sale a la red: anota la petición y responde con [responseBody].
class _RecordingDioClient extends DioClient {
  final Map<String, dynamic> responseBody;
  final List<String> calls = [];

  _RecordingDioClient(this.responseBody);

  @override
  Future<Response> patch(String path, {dynamic data}) async {
    calls.add('PATCH $path');
    return Response(requestOptions: RequestOptions(path: path), statusCode: 200, data: responseBody);
  }
}

void main() {
  test('abandonar el equipo es un PATCH a remove-from-team del propio jugador y devuelve al jugador sin equipo', () async {
    final client = _RecordingDioClient({
      'success': true,
      'data': {'id': 'p1', 'firstName': 'Ana', 'lastName': 'Pérez', 'email': 'ana@email.com', 'teamId': null, 'isCaptain': false},
    });

    final player = await PlayersService(client: client).removeFromTeam('p1');

    expect(client.calls, ['PATCH ${ApiEndpoints.playerRemoveFromTeam('p1')}']);
    expect(player.id, 'p1');
    expect(player.teamId, isNull);
    expect(player.isCaptain, isFalse);
  });

  test('abandonar un equipo dice de cuál sale: un jugador puede jugar en varios, uno por organización', () async {
    final client = _RecordingDioClient({
      'success': true,
      'data': {'id': 'p1', 'firstName': 'Ana', 'lastName': 'Pérez', 'email': 'ana@email.com', 'teamId': 'team-b', 'isCaptain': false},
    });

    final player = await PlayersService(client: client).removeFromTeam('p1', teamId: 'team-a');

    expect(client.calls, ['PATCH /players/p1/remove-from-team?teamId=team-a']);
    // Le queda el otro equipo: el jugador que devuelve el backend sigue jugando allí.
    expect(player.teamId, 'team-b');
  });
}
