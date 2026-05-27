import 'package:sport_platform/core/constants/event_type_ids.dart';
import 'package:sport_platform/modules/events/shared/data/datasource/event_service.dart';

class LeagueService extends EventService {
  LeagueService() : super(eventTypeId: EventTypeIds.league);
}
