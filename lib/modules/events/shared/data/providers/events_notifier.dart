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
}
