import 'package:sport_platform/core/network/json_reader.dart';
import 'package:sport_platform/core/constants/app_constants.dart';
import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/network/response_parser.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/event_status.dart';

/// Una página de eventos y dónde está dentro de la lista completa (lo que responde `GET /events/search`).
class EventsPage {
  final List<EventModel> events;

  /// Índice de esta página, desde 0.
  final int page;
  final int totalPages;
  final int totalElements;

  const EventsPage({
    required this.events,
    required this.page,
    required this.totalPages,
    required this.totalElements,
  });

  /// Quedan más páginas por pedir.
  bool get hasMore => page + 1 < totalPages;

  factory EventsPage.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, resource: 'página de eventos');
    return EventsPage(
      events: reader.list('content', EventModel.fromJson),
      page: reader.requiredInt('page'),
      totalPages: reader.requiredInt('totalPages'),
      totalElements: reader.requiredInt('totalElements'),
    );
  }
}

/// Los eventos que el jugador ve (los de su organización y los públicos), una página a la vez: el backend los ordena por
/// lo que importa (primero los que están en curso, luego los próximos) y filtra por texto y estado.
class EventsSearchService {
  final DioClient _client;

  EventsSearchService({DioClient? client}) : _client = client ?? DioClient();

  Future<EventsPage> search({
    String? text,
    EventStatus? status,
    int page = 0,
    int? size,
  }) async {
    final trimmedText = text?.trim() ?? '';
    final response = await _client.get(
      ApiEndpoints.eventsSearch,
      queryParams: {
        'page': page,
        // Un valor por defecto de parámetro debe ser constante y un enum no lo es: sin tamaño se usa el de AppConstants.
        'size': size ?? AppConstants.listPageSize.value,
        if (trimmedText.isNotEmpty) 'search': trimmedText,
        if (status != null) 'status': status.apiValue,
      },
    );
    return EventsPage.fromJson(ResponseParser.toMap(response.data));
  }
}
