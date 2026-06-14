import '../../data/models/event_schedule_config_model.dart';
import '../../data/models/match_model.dart';

abstract interface class ILeagueScheduleRepository {
  Future<EventScheduleConfigModel?> getConfig(String eventId);
  Future<EventScheduleConfigModel> saveConfig(String eventId, Map<String, dynamic> data);
  Future<List<MatchModel>> generate(String eventId);
}
