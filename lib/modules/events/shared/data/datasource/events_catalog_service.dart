import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/network/response_parser.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';

/// Todos los eventos, de cualquier tipo: lo que necesitan las pantallas que cruzan datos de varios
/// eventos (partidos, rankings, inicio). Las de un solo tipo usan el `EventService` de su tipo.
class EventsCatalogService {
  final DioClient _client;

  EventsCatalogService({DioClient? client}) : _client = client ?? DioClient();

  Future<List<EventModel>> getAll() async {
    final response = await _client.get(ApiEndpoints.events);
    return ResponseParser.toList(response.data)
        .map((item) => EventModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
