import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/matches/data/datasource/match_events_service.dart';
import 'package:sport_platform/modules/matches/presentation/providers/match_detail_notifier.dart';
import 'package:sport_platform/modules/matches/presentation/widgets/match_event_tile.dart';
import 'package:sport_platform/modules/matches/presentation/widgets/match_summary_card.dart';
import 'package:sport_platform/shared/widgets/empty_state.dart';
import 'package:sport_platform/shared/widgets/error_retry.dart';

/// El detalle de un partido: marcador y cronología de goles, asistencias, tarjetas y faltas.
/// Solo lectura: el organizador registra esos eventos desde el panel.
class MatchDetailPage extends StatefulWidget {
  final MatchModel match;
  final String homeName;
  final String awayName;
  final String eventName;
  final String? courtName;

  const MatchDetailPage({
    super.key,
    required this.match,
    required this.homeName,
    required this.awayName,
    this.eventName = '',
    this.courtName,
  });

  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage> {
  late final MatchDetailNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = MatchDetailNotifier(
      service: getIt<MatchEventsService>(),
      matchId: widget.match.id,
    )..load();
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  String _teamNameOf(String teamId) =>
      teamId == widget.match.homeTeamId ? widget.homeName : widget.awayName;

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Scaffold(
      backgroundColor: AppColors.backgroundEnd,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: Text('match_detail.title'.tr(),
            style: const TextStyle(color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: ListenableBuilder(
        listenable: _notifier,
        builder: (context, _) => RefreshIndicator(
          onRefresh: _notifier.load,
          color: AppColors.primaryLight,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              MatchSummaryCard(
                match: widget.match,
                homeName: widget.homeName,
                awayName: widget.awayName,
                eventName: widget.eventName,
                courtName: widget.courtName,
              ),
              const SizedBox(height: 12),
              _buildTimelineTitle(),
              ..._buildTimeline(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineTitle() => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(
          'match_detail.timeline'.tr(),
          style: const TextStyle(
            color: AppColors.primaryLight,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      );

  List<Widget> _buildTimeline() {
    if (_notifier.loading && _notifier.events.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator(color: AppColors.primaryLight)),
        ),
      ];
    }
    final error = _notifier.error;
    if (error != null) {
      return [
        SizedBox(
          height: 260,
          child: ErrorRetry(message: error.tr(), onRetry: _notifier.load),
        ),
      ];
    }
    if (_notifier.events.isEmpty) {
      return [
        SizedBox(
          height: 260,
          child: EmptyState(
            icon: Icons.sports_soccer_outlined,
            title: 'match_detail.empty_title'.tr(),
            subtitle: 'match_detail.empty_subtitle'.tr(),
          ),
        ),
      ];
    }
    return _notifier.events
        .map((event) => MatchEventTile(event: event, teamName: _teamNameOf(event.teamId)))
        .toList();
  }
}
