import 'package:sport_platform/modules/events/shared/data/datasource/event_service.dart';

class LeagueService extends EventService {
  static const _eventTypeId = '30ab7965-8990-46b1-a6b0-71377b62655f';

  LeagueService() : super(eventTypeId: _eventTypeId);
}
