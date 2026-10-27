import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/standings_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/standing_model.dart';
import 'package:sport_platform/shared/widgets/empty_state.dart';
import 'package:sport_platform/shared/widgets/standings_table.dart';

class StandingsTab extends StatelessWidget {
  final StandingsService _standingsService = getIt<StandingsService>();
  final String eventId;

  StandingsTab({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<StandingModel>>(
      future: _standingsService.getById(eventId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryLight),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return EmptyState(
            icon: Icons.leaderboard_outlined,
            title: 'leagues.standings_empty'.tr(),
            subtitle: 'leagues.standings_empty_subtitle'.tr(),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: StandingsTable(rows: snapshot.data!.map(_toRow).toList()),
        );
      },
    );
  }

  static StandingsTableRow _toRow(StandingModel standing) => StandingsTableRow(
        position: standing.position,
        teamName: standing.teamName,
        played: standing.played,
        won: standing.won,
        drawn: standing.drawn,
        lost: standing.lost,
        goalDifference: standing.goalDifference,
        points: standing.points,
      );
}
