import 'package:flutter/material.dart';
import 'package:sport_platform/modules/events/leagues/data/datasource/league_service.dart';
import 'package:sport_platform/modules/events/leagues/presentation/pages/league_detail_page.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/events/shared/presentation/pages/event_type_page.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';

class LeaguesPage extends StatelessWidget {
  final MenuItemModel item;

  const LeaguesPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final service = LeagueService();
    return EventTypePage(
      menuItem: item,
      service: service,
      translationPrefix: 'leagues',
      typeIcon: Icons.military_tech,
      onEventTap: (EventModel event, bool isOwner) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LeagueDetailPage(
              event: event,
              isOwner: isOwner,
              eventService: service,
            ),
          ),
        );
      },
    );
  }
}
