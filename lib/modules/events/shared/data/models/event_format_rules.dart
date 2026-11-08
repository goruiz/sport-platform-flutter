import 'package:sport_platform/modules/events/shared/domain/enums/event_format_structure.dart';
import 'package:sport_platform/modules/events/shared/domain/enums/tiebreaker_criterion.dart';

/// Las reglas de juego del formato de un evento. El backend manda `null` en cada regla que la estructura no usa
/// (una eliminatoria no tiene puntos, un sistema suizo no tiene grupos…), así que un campo nulo es «no aplica».
class EventFormatRules {
  final EventFormatStructure structure;

  /// Liga y fase de grupos: si cada cruce se juega de ida y vuelta o solo de ida.
  final bool? roundTrip;
  final int? pointsForWin;
  final int? pointsForDraw;
  final int? pointsForLoss;

  /// En orden de prioridad; vacía si el formato no define desempates.
  final List<TiebreakerCriterion> tiebreakers;
  final int? swissRounds;
  final int? groupCount;
  final int? teamsAdvancingPerGroup;
  final int? playoffTeams;

  /// Eliminatoria: si cada cruce es de ida y vuelta o un solo partido.
  final bool? knockoutRoundTrip;
  final bool? thirdPlaceMatch;
  final bool? grandFinalReset;

  const EventFormatRules({
    required this.structure,
    this.roundTrip,
    this.pointsForWin,
    this.pointsForDraw,
    this.pointsForLoss,
    this.tiebreakers = const [],
    this.swissRounds,
    this.groupCount,
    this.teamsAdvancingPerGroup,
    this.playoffTeams,
    this.knockoutRoundTrip,
    this.thirdPlaceMatch,
    this.grandFinalReset,
  });

  /// Los tres puntajes juntos, o null si el formato no puntúa (una eliminatoria).
  bool get hasPoints => pointsForWin != null && pointsForDraw != null && pointsForLoss != null;

  /// Null si el formato no trae estructura (uno anterior a las reglas) o trae una que la app no conoce:
  /// sin estructura no hay reglas que mostrar.
  static EventFormatRules? fromJson(Map<String, dynamic>? json) {
    final structure = EventFormatStructure.fromApi(json?['structure']?.toString());
    if (json == null || structure == null) return null;
    return EventFormatRules(
      structure: structure,
      roundTrip: _asBool(json['roundTrip']),
      pointsForWin: _asInt(json['pointsForWin']),
      pointsForDraw: _asInt(json['pointsForDraw']),
      pointsForLoss: _asInt(json['pointsForLoss']),
      tiebreakers: _readTiebreakers(json['tiebreakers']),
      swissRounds: _asInt(json['swissRounds']),
      groupCount: _asInt(json['groupCount']),
      teamsAdvancingPerGroup: _asInt(json['teamsAdvancingPerGroup']),
      playoffTeams: _asInt(json['playoffTeams']),
      knockoutRoundTrip: _asBool(json['knockoutRoundTrip']),
      thirdPlaceMatch: _asBool(json['thirdPlaceMatch']),
      grandFinalReset: _asBool(json['grandFinalReset']),
    );
  }

  /// Un desempate que esta versión de la app no conoce se omite en vez de romper la lista.
  static List<TiebreakerCriterion> _readTiebreakers(dynamic value) {
    if (value is! List) return const [];
    return [for (final item in value) ?TiebreakerCriterion.fromApi(item?.toString())];
  }

  static int? _asInt(dynamic value) => value is num ? value.toInt() : null;

  static bool? _asBool(dynamic value) => value is bool ? value : null;
}
