import 'package:flutter/foundation.dart';
import 'package:sport_platform/core/constants/app_constants.dart';
import 'package:sport_platform/modules/courts/data/datasource/court_availability_service.dart';
import 'package:sport_platform/modules/courts/data/models/court_availability_model.dart';
import 'package:sport_platform/modules/courts/domain/court_agenda.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/matches/data/datasource/matches_service.dart';
import 'package:sport_platform/shared/enums/summary_status.dart';

/// El detalle de una cancha: cómo está el día elegido (horarios libres y ocupados) y los partidos que vienen.
/// Cada bloque se lee por su cuenta, así que uno puede fallar sin tapar al otro.
class CourtDetailNotifier extends ChangeNotifier {
  final CourtAvailabilityService _availabilityService;
  final MatchesService _matchesService;
  final String courtId;
  final DateTime Function() _clock;

  CourtDetailNotifier({
    required CourtAvailabilityService availabilityService,
    required MatchesService matchesService,
    required this.courtId,
    DateTime Function()? clock,
  }) : _availabilityService = availabilityService,
       _matchesService = matchesService,
       _clock = clock ?? DateTime.now {
    _days = buildAgendaDays(_clock(), count: AppConstants.courtAgendaDays.value);
    _selectedDay = _days.first;
  }

  late final List<DateTime> _days;
  late DateTime _selectedDay;
  SummaryStatus _availabilityStatus = SummaryStatus.loading;
  CourtAvailabilityModel? _availability;
  SummaryStatus _matchesStatus = SummaryStatus.loading;
  List<MatchModel> _matches = const [];

  /// Cuenta las lecturas de cada bloque: la respuesta de una que ya no es la última (se cambió de día o se
  /// refrescó) se descarta.
  int _availabilityRequest = 0;
  int _matchesRequest = 0;
  bool _isDisposed = false;

  /// Los días que se pueden consultar.
  List<DateTime> get days => _days;
  DateTime get selectedDay => _selectedDay;
  SummaryStatus get availabilityStatus => _availabilityStatus;
  CourtAvailabilityModel? get availability => _availability;
  SummaryStatus get matchesStatus => _matchesStatus;

  /// Los partidos que vienen en la cancha, los más próximos primero y hasta el límite que se muestra.
  List<MatchModel> get upcomingMatches => _matches;

  Future<void> load() => Future.wait([loadAvailability(), _loadMatches()]);

  /// Elige otro día y lee sus horarios. Elegir el que ya está no repite la lectura.
  Future<void> selectDay(DateTime day) async {
    if (day == _selectedDay) return;
    _selectedDay = day;
    await loadAvailability();
  }

  Future<void> loadAvailability() async {
    final request = ++_availabilityRequest;
    _availabilityStatus = SummaryStatus.loading;
    _notify();
    CourtAvailabilityModel? availability;
    var status = SummaryStatus.ready;
    try {
      availability = await _availabilityService.getByDay(courtId, _selectedDay);
    } catch (_) {
      status = SummaryStatus.failed;
    }
    if (request != _availabilityRequest) return;
    _availability = availability;
    _availabilityStatus = status;
    _notify();
  }

  Future<void> _loadMatches() async {
    final request = ++_matchesRequest;
    _matchesStatus = SummaryStatus.loading;
    _notify();
    List<MatchModel> matches = const [];
    var status = SummaryStatus.ready;
    try {
      matches = await _matchesService.getByCourt(courtId, from: _clock());
    } catch (_) {
      status = SummaryStatus.failed;
    }
    if (request != _matchesRequest) return;
    _matches = List.unmodifiable(matches.take(AppConstants.courtUpcomingMatchesLimit.value));
    _matchesStatus = status;
    _notify();
  }

  Future<void> retryMatches() => _loadMatches();

  /// Una lectura que termina después de cerrar la pantalla no debe avisar a nadie.
  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
