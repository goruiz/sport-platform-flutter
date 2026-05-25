import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import '../local/my_events_store.dart';
import '../models/event_model.dart';

/// Base service for any event-type module (leagues, tournaments, friendlies…).
/// Subclasses only need to provide [eventTypeId].
class EventService {
  final String eventTypeId;
  final DioClient _client = DioClient();

  EventService({required this.eventTypeId});

  Future<List<EventModel>> getAll() async {
    final response =
        await _client.get(ApiEndpoints.eventsByType(eventTypeId));
    final dynamic raw = response.data;
    final List<dynamic> list =
        raw is List ? raw : (raw['data'] as List<dynamic>);
    return list
        .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Set<String>> getMyIds() => MyEventsStore.getIds(eventTypeId);

  Future<EventModel> create(Map<String, dynamic> data) async {
    final payload = {...data, 'idEventType': eventTypeId};
    final response = await _client.post(ApiEndpoints.events, data: payload);
    final dynamic raw = response.data;
    final Map<String, dynamic> json = raw is Map<String, dynamic>
        ? raw
        : raw['data'] as Map<String, dynamic>;
    final created = EventModel.fromJson(json);
    await MyEventsStore.add(eventTypeId, created.id);
    return created;
  }

  Future<EventModel> update(String id, Map<String, dynamic> data) async {
    final response =
        await _client.put(ApiEndpoints.eventById(id), data: data);
    final dynamic raw = response.data;
    final Map<String, dynamic> json = raw is Map<String, dynamic>
        ? raw
        : raw['data'] as Map<String, dynamic>;
    return EventModel.fromJson(json);
  }

  Future<void> delete(String id) async {
    await _client.delete(ApiEndpoints.eventById(id));
    await MyEventsStore.remove(eventTypeId, id);
  }
}
