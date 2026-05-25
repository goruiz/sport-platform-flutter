import 'package:flutter/material.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/events/leagues/data/datasource/league_service.dart';
import 'package:sport_platform/modules/events/shared/presentation/pages/event_type_page.dart';

class LeaguesPage extends StatelessWidget {
  final MenuItemModel item;

  const LeaguesPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return EventTypePage(
      menuItem: item,
      service: LeagueService(),
      translationPrefix: 'leagues',
      typeIcon: Icons.military_tech,
    );
  }
}
