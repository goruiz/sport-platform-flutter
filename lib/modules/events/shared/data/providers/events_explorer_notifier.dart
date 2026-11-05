import 'package:flutter/foundation.dart';
import 'package:sport_platform/modules/events/shared/data/datasource/events_search_service.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/event_status.dart';

/// El estado de la pantalla que explora los eventos: lo que se busca, el estado elegido y las páginas que ya se
/// descargaron. Pide una página a la vez y descarta la respuesta de una búsqueda que ya no es la actual, para que una
/// respuesta lenta nunca pise a una más nueva.
class EventsExplorerNotifier extends ChangeNotifier {
  static const _loadErrorKey = 'mobile.events.load_error';

  final EventsSearchService _service;

  EventsExplorerNotifier(this._service);

  String _text = '';
  EventStatus? _status;
  List<EventModel> _events = [];
  int _loadedPages = 0;
  int _totalElements = 0;
  bool _hasMore = false;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;

  /// Cada búsqueda nueva sube el número: una respuesta que llega con otro número ya no es de la búsqueda actual.
  int _searchGeneration = 0;

  String get text => _text;
  EventStatus? get status => _status;
  List<EventModel> get events => List.unmodifiable(_events);
  int get totalElements => _totalElements;
  bool get hasMore => _hasMore;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;

  /// Clave de traducción del último error (no el texto): sigue al idioma activo.
  String? get error => _error;

  /// Hay alguna búsqueda o filtro puesto (para decir «sin resultados» en vez de «aún no hay eventos»).
  bool get isFiltering => _text.trim().isNotEmpty || _status != null;

  Future<void> load() => _reload();

  Future<void> search(String text) {
    if (text == _text) return Future.value();
    _text = text;
    return _reload();
  }

  Future<void> selectStatus(EventStatus? status) {
    if (status == _status) return Future.value();
    _status = status;
    return _reload();
  }

  Future<void> _reload() async {
    final generation = ++_searchGeneration;
    _loading = true;
    _loadingMore = false;
    _error = null;
    notifyListeners();
    try {
      final page = await _service.search(text: _text, status: _status);
      if (generation != _searchGeneration) return;
      _events = page.events;
      _loadedPages = 1;
      _totalElements = page.totalElements;
      _hasMore = page.hasMore;
    } catch (_) {
      if (generation != _searchGeneration) return;
      _events = [];
      _hasMore = false;
      _error = _loadErrorKey;
    } finally {
      if (generation == _searchGeneration) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  /// Pide la página que sigue y la suma a las que ya hay. No hace nada si no quedan o si ya se está pidiendo una.
  Future<void> loadMore() async {
    if (!_hasMore || _loading || _loadingMore) return;
    final generation = _searchGeneration;
    _loadingMore = true;
    notifyListeners();
    try {
      final page = await _service.search(text: _text, status: _status, page: _loadedPages);
      if (generation != _searchGeneration) return;
      _events = [..._events, ...page.events];
      _loadedPages += 1;
      _totalElements = page.totalElements;
      _hasMore = page.hasMore;
    } catch (_) {
      if (generation != _searchGeneration) return;
      _error = _loadErrorKey;
    } finally {
      if (generation == _searchGeneration) {
        _loadingMore = false;
        notifyListeners();
      }
    }
  }
}
