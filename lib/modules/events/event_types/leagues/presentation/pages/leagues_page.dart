import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/pages/league_detail_page.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/events/shared/data/providers/events_notifier.dart';
import 'package:sport_platform/modules/events/shared/presentation/pages/event_type_page.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';

class LeaguesPage extends StatelessWidget {
  final MenuItemModel item;

  const LeaguesPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: getIt<EventsNotifier>(instanceName: 'leagues'),
      child: EventTypePage(
        menuItem: item,
        translationPrefix: 'leagues',
        typeIcon: Icons.military_tech,
        onEventTap: (EventModel event, bool isOwner) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LeagueDetailPage(
                event: event,
                isOwner: isOwner,
              ),
            ),
          );
        },
      ),
    );
  }
}
