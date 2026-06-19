import '../../data/models/match_model.dart';

abstract interface class ILeagueMatchesRepository {
  Future<List<MatchModel>> getByEvent(String eventId);
  Future<MatchModel> create(Map<String, dynamic> data);
  Future<MatchModel> update(String id, Map<String, dynamic> data);
  Future<void> delete(String id);
  Future<List<MatchModel>> rescheduleDate(
    String eventId,
    DateTime fromDate, {
    DateTime? toDate,
  });
  Future<MatchModel> postpone(String id);
  Future<MatchModel> suspend(String id);
  Future<MatchModel> reschedule(String id, DateTime newDate);
}
