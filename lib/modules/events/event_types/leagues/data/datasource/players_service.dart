import 'package:dio/dio.dart';
import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import '../models/player_model.dart';

class PlayersService {
  final DioClient _client = DioClient();

  Future<PlayerModel> create({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String teamId,
    String? phone,
  }) async {
    final response = await _client.post(
      ApiEndpoints.players,
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'teamId': teamId,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
    final dynamic raw = response.data;
    final Map<String, dynamic> data =
        raw is Map<String, dynamic> && raw.containsKey('data')
            ? raw['data'] as Map<String, dynamic>
            : raw as Map<String, dynamic>;
    return PlayerModel.fromJson(data);
  }

  /// Returns the found user or null if not registered.
  Future<PlayerModel?> searchByEmail(String email) async {
    try {
      final response = await _client.get(
        ApiEndpoints.playersSearch,
        queryParams: {'email': email},
      );
      final dynamic raw = response.data;
      if (raw == null) return null;
      final Map<String, dynamic>? data =
          raw is Map<String, dynamic> && raw.containsKey('data')
              ? raw['data'] as Map<String, dynamic>?
              : raw is Map<String, dynamic>
                  ? raw
                  : null;
      if (data == null) return null;
      return PlayerModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Sends an invitation email to an existing user to join the team.
  Future<void> inviteExistingUser({
    required String email,
    required String teamId,
  }) async {
    await _client.post(
      ApiEndpoints.playersInvite,
      data: {'email': email, 'teamId': teamId},
    );
  }

  Future<PlayerModel> updatePlayer(
    String playerId, {
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    final body = <String, dynamic>{
      if (firstName case final v?) 'firstName': v,
      if (lastName case final v?) 'lastName': v,
      if (phone case final v?) 'phone': v,
    };
    final response = await _client.put(
      ApiEndpoints.playerById(playerId),
      data: body,
    );
    final dynamic raw = response.data;
    final Map<String, dynamic> data =
        raw is Map<String, dynamic> && raw.containsKey('data')
            ? raw['data'] as Map<String, dynamic>
            : raw as Map<String, dynamic>;
    return PlayerModel.fromJson(data);
  }

  Future<PlayerModel> removeFromTeam(String playerId) async {
    final response = await _client.patch(
      ApiEndpoints.playerRemoveFromTeam(playerId),
    );
    final dynamic raw = response.data;
    final Map<String, dynamic> data =
        raw is Map<String, dynamic> && raw.containsKey('data')
            ? raw['data'] as Map<String, dynamic>
            : raw as Map<String, dynamic>;
    return PlayerModel.fromJson(data);
  }

  Future<List<PlayerModel>> getByTeamId(String teamId) async {
    final response = await _client.get(ApiEndpoints.playersByTeam(teamId));
    final dynamic raw = response.data;
    final List<dynamic> list =
        raw is Map<String, dynamic> && raw.containsKey('data')
            ? raw['data'] as List<dynamic>
            : raw as List<dynamic>;
    return list
        .map((e) => PlayerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Sends a registration link to an unregistered email.
  /// Once the user registers, they are automatically added to the team.
  Future<void> inviteNewUser({
    required String email,
    required String teamId,
  }) async {
    await _client.post(
      ApiEndpoints.playersInviteRegister,
      data: {'email': email, 'teamId': teamId},
    );
  }
}
