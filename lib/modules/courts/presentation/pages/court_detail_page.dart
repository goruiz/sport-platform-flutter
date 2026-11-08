import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/modules/courts/presentation/providers/court_detail_notifier.dart';
import 'package:sport_platform/modules/courts/presentation/widgets/court_schedule_section.dart';
import 'package:sport_platform/modules/courts/presentation/widgets/court_upcoming_matches_section.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/court_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/matches/presentation/pages/match_detail_page.dart';
import 'package:sport_platform/modules/sport_complexes/domain/complex_overview.dart';
import 'package:sport_platform/modules/sport_complexes/presentation/pages/sport_complex_detail_page.dart';
import 'package:sport_platform/shared/widgets/app_card.dart';

/// Una cancha: dónde está, qué horarios tiene libres cada día y qué partidos se juegan en ella.
///
/// [complex] es el complejo al que pertenece, con su mapa; si es null no se ofrece el enlace (por ejemplo, cuando se
/// llegó a la cancha desde el propio complejo).
class CourtDetailPage extends StatefulWidget {
  final CourtModel court;
  final ComplexOverview? complex;

  const CourtDetailPage({super.key, required this.court, this.complex});

  @override
  State<CourtDetailPage> createState() => _CourtDetailPageState();
}

class _CourtDetailPageState extends State<CourtDetailPage> {
  late final CourtDetailNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = CourtDetailNotifier(
      availabilityService: getIt(),
      matchesService: getIt(),
      courtId: widget.court.id,
    )..load();
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  void _openComplex(ComplexOverview complex) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SportComplexDetailPage(overview: complex)),
    );
  }

  void _openMatch(MatchModel match) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MatchDetailPage(
          match: match,
          homeName: match.homeTeamName ?? '—',
          awayName: match.awayTeamName ?? '—',
          eventName: match.eventName ?? '',
          courtName: widget.court.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Scaffold(
      backgroundColor: AppColors.backgroundEnd,
      appBar: AppBar(title: Text(widget.court.name)),
      body: ListenableBuilder(
        listenable: _notifier,
        builder: (context, _) => RefreshIndicator(
          onRefresh: _notifier.load,
          color: AppColors.primaryLight,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.lg,
              AppSpacing.page,
              AppSpacing.listBottom,
            ),
            children: [
              _buildInfoCard(),
              const SizedBox(height: AppSpacing.section),
              _buildSectionTitle('mobile.courts.schedule_title'.tr()),
              CourtScheduleSection(
                days: _notifier.days,
                selectedDay: _notifier.selectedDay,
                status: _notifier.availabilityStatus,
                availability: _notifier.availability,
                onDaySelected: _notifier.selectDay,
                onRetry: _notifier.loadAvailability,
              ),
              const SizedBox(height: AppSpacing.section),
              _buildSectionTitle('mobile.courts.upcoming_title'.tr()),
              CourtUpcomingMatchesSection(
                status: _notifier.matchesStatus,
                matches: _notifier.upcomingMatches,
                onMatchTap: _openMatch,
                onRetry: _notifier.retryMatches,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// El complejo y la ubicación de la cancha, su descripción y, si se conoce el complejo, el paso a su mapa.
  Widget _buildInfoCard() {
    final court = widget.court;
    final complex = widget.complex;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (court.sportComplexName?.isNotEmpty ?? false)
            _InfoLine(icon: Icons.stadium_outlined, text: court.sportComplexName!),
          if (court.location?.isNotEmpty ?? false)
            _InfoLine(icon: Icons.place_outlined, text: court.location!),
          if (court.description?.isNotEmpty ?? false)
            _InfoLine(icon: Icons.info_outline, text: court.description!),
          if (complex != null) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openComplex(complex),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: Text('mobile.courts.view_complex'.tr()),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.md),
        child: Text(text, style: AppTextStyles.sectionTitle),
      );
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.primaryLight),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(text, style: AppTextStyles.body)),
          ],
        ),
      );
}
