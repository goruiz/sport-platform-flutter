import 'package:flutter/foundation.dart';
import 'package:sport_platform/modules/matches/data/datasource/match_events_service.dart';
import 'package:sport_platform/modules/matches/data/models/match_event_model.dart';

/// El estado de la pantalla de un partido: su cronología de goles, tarjetas y demás.
class MatchDetailNotifier extends ChangeNotifier {
  final MatchEventsService _service;
  final String matchId;

  List<MatchEventModel> _events = [];
  bool _loading = true;

  /// Clave de traducción del error de la carga (no el texto): sigue al idioma activo.
  String? _error;

  MatchDetailNotifier({required MatchEventsService service, required this.matchId})
      : _service = service;

  List<MatchEventModel> get events => List.unmodifiable(_events);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _events = await _service.getByMatch(matchId);
    } catch (_) {
      _error = 'match_detail.error_load';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
