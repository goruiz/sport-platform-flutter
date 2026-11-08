import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/network/response_parser.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';
import 'package:sport_platform/modules/users/domain/profile_photo_rules.dart';

/// La foto de perfil del jugador de la cuenta. El backend la guarda en su base de datos y deja en el jugador su
/// dirección (`profilePhotoUrl`, relativa al API). Los rechazos llegan como excepción de la petición: el notifier los lee.
class PlayerPhotoService {
  /// El campo del formulario en que el backend espera el archivo.
  static const String _fileField = 'file';

  final DioClient _client;

  PlayerPhotoService({DioClient? client}) : _client = client ?? DioClient();

  /// Sube [bytes] como la foto del jugador y devuelve el jugador con su foto nueva.
  Future<PlayerModel> upload({required Uint8List bytes, required String fileName}) async {
    final mimeType = imageMimeTypeOf(fileName);
    final form = FormData.fromMap({
      _fileField: MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: mimeType == null ? null : DioMediaType.parse(mimeType),
      ),
    });
    final response = await _client.put(ApiEndpoints.playersMePhoto, data: form);
    return PlayerModel.fromJson(ResponseParser.toMap(response.data));
  }

  /// Quita la foto del jugador y devuelve el jugador sin ella.
  Future<PlayerModel> remove() async {
    final response = await _client.delete(ApiEndpoints.playersMePhoto);
    return PlayerModel.fromJson(ResponseParser.toMap(response.data));
  }
}
