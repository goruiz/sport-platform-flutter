import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/app_constants.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/matches/data/datasource/match_attendance_service.dart';
import 'package:sport_platform/modules/matches/data/datasource/match_disputes_service.dart';
import 'package:sport_platform/core/services/external_launcher.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/core/utils/date_formatters.dart';
import 'package:sport_platform/core/utils/external_links.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/matches/data/datasource/match_events_service.dart';
import 'package:sport_platform/modules/matches/presentation/providers/match_attendance_notifier.dart';
import 'package:sport_platform/modules/matches/presentation/providers/match_detail_notifier.dart';
import 'package:sport_platform/modules/matches/presentation/providers/match_result_dispute_notifier.dart';
import 'package:sport_platform/modules/matches/presentation/widgets/match_attendance_card.dart';
import 'package:sport_platform/modules/matches/presentation/widgets/match_event_tile.dart';
import 'package:sport_platform/modules/matches/presentation/widgets/match_result_dispute_card.dart';
import 'package:sport_platform/modules/matches/presentation/widgets/match_result_dispute_sheet.dart';
import 'package:sport_platform/modules/matches/presentation/widgets/match_scoreboard.dart';
import 'package:sport_platform/modules/users/presentation/providers/account_capabilities_notifier.dart';
import 'package:sport_platform/shared/widgets/app_card.dart';
import 'package:sport_platform/shared/widgets/app_snackbar.dart';
import 'package:sport_platform/shared/widgets/empty_state.dart';
import 'package:sport_platform/shared/widgets/error_retry.dart';
import 'package:sport_platform/shared/enums/summary_status.dart';
import 'package:sport_platform/shared/widgets/status_badge.dart';

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
  late final MatchAttendanceNotifier _attendance;
  late final MatchResultDisputeNotifier _dispute;

  @override
  void initState() {
    super.initState();
    _notifier = MatchDetailNotifier(
      service: getIt<MatchEventsService>(),
      matchId: widget.match.id,
    )..load();
    _attendance = MatchAttendanceNotifier(
      playersService: getIt<PlayersService>(),
      service: getIt<MatchAttendanceService>(),
      match: widget.match,
    )..load();
    _dispute = MatchResultDisputeNotifier(
      capabilities: getIt<AccountCapabilitiesNotifier>(),
      playersService: getIt<PlayersService>(),
      service: getIt<MatchDisputesService>(),
      match: widget.match,
    )..load();
  }

  @override
  void dispose() {
    _notifier.dispose();
    _attendance.dispose();
    _dispute.dispose();
    super.dispose();
  }

  /// Guarda lo que el jugador responde (o quita su respuesta) y, si el backend lo rechaza, dice por qué.
  Future<void> _saveAttendance(Future<String?> Function() save) async {
    final problemKey = await save();
    if (!mounted || problemKey == null) return;
    AppSnackbar.error(context, problemKey.tr());
  }

  String _teamNameOf(String teamId) =>
      teamId == widget.match.homeTeamId ? widget.homeName : widget.awayName;

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Scaffold(
      backgroundColor: AppColors.backgroundEnd,
      appBar: AppBar(title: Text('match_detail.title'.tr())),
      body: ListenableBuilder(
        listenable: Listenable.merge([_notifier, _attendance, _dispute]),
        builder: (context, _) => RefreshIndicator(
          onRefresh: () => Future.wait([
            _notifier.load(),
            _attendance.load(),
            _dispute.load(forceCapabilities: true),
          ]),
          color: AppColors.primaryLight,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _buildHeaderCard(),
              const SizedBox(height: AppSpacing.md),
              _buildActions(),
              ..._buildAttendance(),
              ..._buildResultDispute(),
              const SizedBox(height: AppSpacing.xxl),
              _buildTimelineTitle(),
              ..._buildTimeline(),
            ],
          ),
        ),
      ),
    );
  }

  /// El marcador grande: evento y estado arriba, los equipos con su escudo, y el lugar abajo.
  Widget _buildHeaderCard() {
    final match = widget.match;
    final place = widget.courtName ?? match.location;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: widget.eventName.isEmpty
                    ? const SizedBox.shrink()
                    : Text(
                        widget.eventName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
              ),
              StatusBadge.forMatch(match.status),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          MatchScoreboard(
            match: match,
            homeName: widget.homeName,
            awayName: widget.awayName,
            large: true,
          ),
          if (place != null && place.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: AppColors.whiteSubtle),
                  const SizedBox(width: 6),
                  Flexible(child: Text(place, style: AppTextStyles.caption)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Compartir el partido y agregarlo al calendario del dispositivo.
  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _share,
            icon: const Icon(Icons.share_outlined, size: 18),
            label: Text('match_detail.share'.tr()),
          ),
        ),
        if (!widget.match.hasScore) ...[
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _addToCalendar,
              icon: const Icon(Icons.event_available_outlined, size: 18),
              label: Text('match_detail.add_to_calendar'.tr()),
            ),
          ),
        ],
      ],
    );
  }

  /// La asistencia, solo para quien juega en uno de los equipos del partido: nadie más la ve.
  List<Widget> _buildAttendance() {
    if (!_attendance.isParticipant) return const [];
    final attendance = _attendance.attendance;
    if (_attendance.status == SummaryStatus.failed || attendance == null) {
      if (_attendance.status == SummaryStatus.loading) return const [];
      return [
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  (_attendance.loadErrorKey ?? 'match_detail.attendance.error_load').tr(),
                  style: AppTextStyles.bodyMuted,
                ),
              ),
              TextButton(onPressed: _attendance.load, child: Text('common.retry'.tr())),
            ],
          ),
        ),
      ];
    }
    return [
      const SizedBox(height: AppSpacing.md),
      MatchAttendanceCard(
        attendance: attendance,
        myTeamId: _attendance.myTeamId,
        canAnswer: _attendance.canAnswer,
        isSaving: _attendance.isSaving,
        onAnswer: (status) => _saveAttendance(() => _attendance.answer(status)),
        onClearAnswer: () => _saveAttendance(_attendance.clearAnswer),
      ),
    ];
  }

  /// «¿Hay un problema con el resultado?», solo para el dirigente de uno de los equipos del partido: nadie más la ve.
  List<Widget> _buildResultDispute() {
    if (_dispute.status == SummaryStatus.loading) return const [];
    if (_dispute.status == SummaryStatus.failed) {
      return [
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  (_dispute.loadErrorKey ?? 'match_detail.dispute.error_load').tr(),
                  style: AppTextStyles.bodyMuted,
                ),
              ),
              TextButton(onPressed: _dispute.load, child: Text('common.retry'.tr())),
            ],
          ),
        ),
      ];
    }
    if (!_dispute.isAvailable) return const [];
    return [
      const SizedBox(height: AppSpacing.md),
      MatchResultDisputeCard(
        disputes: _dispute.disputes,
        homeName: widget.homeName,
        awayName: widget.awayName,
        isSaving: _dispute.isSaving,
        onReport: _reportResultProblem,
      ),
    ];
  }

  /// Abre el formulario del aviso y, si se envió, lo confirma.
  Future<void> _reportResultProblem() async {
    final wasSent = await MatchResultDisputeSheet.show(
      context: context,
      match: widget.match,
      homeName: widget.homeName,
      awayName: widget.awayName,
      onSend: _dispute.report,
    );
    if (!mounted || wasSent != true) return;
    AppSnackbar.success(context, 'match_detail.dispute.sent'.tr());
  }

  /// El resultado si ya hay, y si no, quién juega con quién y cuándo.
  String _shareText() {
    final match = widget.match;
    final headline = match.hasScore
        ? 'match_detail.share_result'.tr(
            args: [widget.homeName, '${match.homeScore}', '${match.awayScore}', widget.awayName])
        : 'match_detail.share_upcoming'.tr(args: [widget.homeName, widget.awayName]);
    return [
      headline,
      if (widget.eventName.isNotEmpty) widget.eventName,
      DateFormatters.dateTime(match.matchDate),
      if (widget.courtName != null) widget.courtName!,
    ].join('\n');
  }

  Future<void> _share() async {
    final shared = await ExternalLauncher.shareText(_shareText());
    if (!shared && mounted) AppSnackbar.error(context, 'match_detail.action_error'.tr());
  }

  Future<void> _addToCalendar() async {
    final match = widget.match;
    final uri = ExternalLinks.calendarEvent(
      title: 'match_detail.calendar_title'.tr(args: [widget.homeName, widget.awayName]),
      start: match.matchDate,
      end: match.endsAt ?? match.matchDate.add(AppConstants.defaultMatchDuration.value),
      location: widget.courtName ?? match.location,
      details: widget.eventName,
    );
    final opened = await ExternalLauncher.open(uri);
    if (!opened && mounted) AppSnackbar.error(context, 'match_detail.action_error'.tr());
  }

  Widget _buildTimelineTitle() => Padding(
        padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.md),
        child: Text('match_detail.timeline'.tr(), style: AppTextStyles.sectionTitle),
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
