import '../../data/models/match_model.dart';

abstract interface class ILeagueMatchesRepository {
  Future<List<MatchModel>> getByEvent(String eventId);
}
