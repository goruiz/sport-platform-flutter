import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';

/// El capitán va primero; los demás conservan el orden en que los manda el backend.
List<PlayerModel> sortCaptainFirst(List<PlayerModel> members) => [
      ...members.where((member) => member.isCaptain),
      ...members.where((member) => !member.isCaptain),
    ];
