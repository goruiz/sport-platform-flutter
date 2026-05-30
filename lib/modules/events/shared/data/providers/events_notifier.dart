import 'package:flutter/material.dart';
import 'package:sport_platform/modules/events/shared/data/datasource/event_service.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';

class EventsNotifier extends ChangeNotifier {
  final EventService _service;

  List<EventModel> _all = [];
  Set<String> _myIds = {};
  bool _loading = false;
  String? _error;
  DateTime? _lastFetched;

  static const _ttl = Duration(minutes: 3);

  EventsNotifier(this._service);

  List<EventModel> get all => List.unmodifiable(_all);
  Set<String> get myIds => Set.unmodifiable(_myIds);
  bool get loading => _loading;
  String? get error => _error;
  List<EventModel> get mine =>
      _all.where((e) => _myIds.contains(e.id)).toList();

  bool get _isFresh =>
      _lastFetched != null &&
      DateTime.now().difference(_lastFetched!) < _ttl;

  Future<void> load({bool force = false}) async {
    if (!force && _isFresh) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.getAll(),
        _service.getMyIds(),
      ]);
      _all = results[0] as List<EventModel>;
      _myIds = results[1] as Set<String>;
      _lastFetched = DateTime.now();
    } catch (_) {
      _error = 'error';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<EventModel> create(Map<String, dynamic> data) async {
    final created = await _service.create(data);
    _all.insert(0, created);
    _myIds.add(created.id);
    notifyListeners();
    return created;
  }

  Future<EventModel> update(String id, Map<String, dynamic> data) async {
    final updated = await _service.update(id, data);
    final idx = _all.indexWhere((e) => e.id == id);
    if (idx != -1) _all[idx] = updated;
    notifyListeners();
    return updated;
  }

  Future<void> delete(String id) async {
    await _service.delete(id);
    _all.removeWhere((e) => e.id == id);
    _myIds.remove(id);
    notifyListeners();
  }

  Future<void> silentReload() async {
    try {
      final results = await Future.wait([
        _service.getAll(),
        _service.getMyIds(),
      ]);
      _all = results[0] as List<EventModel>;
      _myIds = results[1] as Set<String>;
      notifyListeners();
    } catch (_) {}
  }
}
