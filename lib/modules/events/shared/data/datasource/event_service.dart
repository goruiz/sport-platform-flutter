import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/services/user_session.dart';
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

  /// Fetches the IDs of events belonging to the current user for this type,
  /// using the backend endpoint /events/by-event-type/{typeId}/by-user/{userId}.
  Future<Set<String>> getMyIds() async {
    await UserSession.loadFromStorage();
    final userId = UserSession.current?.id;
    final u = UserSession.current;
    print('UserSession.current: id=${u?.id}, idRole=${u?.idRole}, username=${u?.username}, email=${u?.email}, firstName=${u?.firstName}, lastName=${u?.lastName}');
    print('URL llamada: ${ApiEndpoints.eventsByTypeAndUser(eventTypeId, userId ?? 'NULL')}');
    if (userId == null || userId.isEmpty) return {};

    final response = await _client.get(
      ApiEndpoints.eventsByTypeAndUser(eventTypeId, userId),
    );
    final dynamic raw = response.data;
    final List<dynamic> list =
        raw is List ? raw : (raw['data'] as List<dynamic>);
    return list
        .map((e) => (e as Map<String, dynamic>)['id'] as String)
        .toSet();
  }

  Future<EventModel> create(Map<String, dynamic> data) async {
    final payload = {...data, 'idEventType': eventTypeId};
    final response = await _client.post(ApiEndpoints.events, data: payload);
    return EventModel.fromJson(_unwrap(response.data));
  }

  Future<EventModel> update(String id, Map<String, dynamic> data) async {
    final response = await _client.put(ApiEndpoints.eventById(id), data: data);
    return EventModel.fromJson(_unwrap(response.data));
  }

  /// Extrae el objeto del evento ya sea directo o dentro de {"data": {...}}.
  static Map<String, dynamic> _unwrap(dynamic raw) {
    final map = raw as Map<String, dynamic>;
    if (map['data'] is Map<String, dynamic>) {
      return map['data'] as Map<String, dynamic>;
    }
    return map;
  }

  Future<void> delete(String id) async {
    await _client.delete(ApiEndpoints.eventById(id));
  }
}
