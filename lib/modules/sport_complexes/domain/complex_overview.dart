import 'package:sport_platform/core/utils/text_folding.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/court_model.dart';
import 'package:sport_platform/modules/sport_complexes/data/models/sport_complex_model.dart';

/// Un complejo con sus canchas, como lo muestra la pantalla.
class ComplexOverview {
  final SportComplexModel complex;
  final List<CourtModel> courts;

  const ComplexOverview({required this.complex, required this.courts});
}

/// Junta cada cancha con su complejo (por `sportComplexId`). Complejos y canchas salen por nombre, sin
/// distinguir mayúsculas ni tildes; una cancha sin complejo, o de uno que el jugador no ve, no aparece.
List<ComplexOverview> buildComplexOverviews(
  List<SportComplexModel> complexes,
  List<CourtModel> courts,
) {
  final courtsByComplexId = <String, List<CourtModel>>{};
  for (final court in courts) {
    final complexId = court.sportComplexId;
    if (complexId == null) continue;
    courtsByComplexId.putIfAbsent(complexId, () => []).add(court);
  }

  final overviews = [
    for (final complex in complexes)
      ComplexOverview(
        complex: complex,
        courts: [...?courtsByComplexId[complex.id]]..sort(_compareCourtsByName),
      ),
  ]..sort((a, b) => _compareNames(a.complex.name, b.complex.name));
  return overviews;
}

/// Los complejos de [overviews] cuyo id está en [complexIds] (los de los eventos del equipo), en el mismo orden.
List<ComplexOverview> filterComplexOverviewsByIds(List<ComplexOverview> overviews, Set<String> complexIds) =>
    overviews.where((overview) => complexIds.contains(overview.complex.id)).toList();

/// Las canchas que no pertenecen a ningún complejo (las registradas cuando el complejo era opcional), por nombre.
List<CourtModel> listCourtsWithoutComplex(List<CourtModel> courts) =>
    courts.where((court) => (court.sportComplexId ?? '').isEmpty).toList()..sort(_compareCourtsByName);

/// Los que coinciden con [query] en el nombre, la dirección, la descripción o el nombre de alguna cancha, sin
/// distinguir mayúsculas ni tildes.
List<ComplexOverview> filterComplexOverviews(
  List<ComplexOverview> overviews,
  String query,
) {
  final normalizedQuery = foldForComparison(query.trim());
  if (normalizedQuery.isEmpty) return overviews;

  bool matches(String? text) => text != null && foldForComparison(text).contains(normalizedQuery);

  return overviews
      .where(
        (overview) =>
            matches(overview.complex.name) ||
            matches(overview.complex.location) ||
            matches(overview.complex.description) ||
            overview.courts.any((court) => matches(court.name)),
      )
      .toList();
}

/// Las canchas que coinciden con [query] en el nombre, la descripción o la ubicación, sin distinguir mayúsculas ni tildes.
List<CourtModel> filterCourtsByQuery(List<CourtModel> courts, String query) {
  final normalizedQuery = foldForComparison(query.trim());
  if (normalizedQuery.isEmpty) return courts;

  bool matches(String? text) => text != null && foldForComparison(text).contains(normalizedQuery);

  return courts
      .where((court) => matches(court.name) || matches(court.description) || matches(court.location))
      .toList();
}

int _compareNames(String a, String b) => foldForComparison(a).compareTo(foldForComparison(b));

int _compareCourtsByName(CourtModel a, CourtModel b) => _compareNames(a.name, b.name);
