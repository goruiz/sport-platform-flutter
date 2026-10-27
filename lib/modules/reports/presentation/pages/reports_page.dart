import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/reports/domain/team_report.dart';
import 'package:sport_platform/modules/reports/presentation/providers/reports_notifier.dart';
import 'package:sport_platform/modules/reports/presentation/widgets/recent_form_chips.dart';
import 'package:sport_platform/modules/reports/presentation/widgets/team_record_card.dart';
import 'package:sport_platform/shared/widgets/empty_state.dart';
import 'package:sport_platform/shared/widgets/error_retry.dart';

/// El reporte del equipo del usuario: su balance, su racha y cómo le fue en cada evento.
class ReportsPage extends StatefulWidget {
  final MenuItemModel item;

  const ReportsPage({super.key, required this.item});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late final ReportsNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = ReportsNotifier(
      playersService: getIt(),
      matchesService: getIt(),
      eventsService: getIt(),
    )..load();
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Scaffold(
      backgroundColor: AppColors.backgroundEnd,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: Text(widget.item.localizedName,
            style: const TextStyle(color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
        actions: [
          IconButton(
            onPressed: _notifier.load,
            tooltip: 'common.retry'.tr(),
            icon: const Icon(Icons.refresh, color: AppColors.white),
          ),
        ],
      ),
      body: ListenableBuilder(listenable: _notifier, builder: (_, _) => _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_notifier.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryLight),
      );
    }
    final error = _notifier.error;
    if (error != null) return ErrorRetry(message: error.tr(), onRetry: _notifier.load);
    if (!_notifier.hasTeam) {
      return EmptyState(
        icon: Icons.groups_outlined,
        title: 'reports.no_team_title'.tr(),
        subtitle: 'reports.no_team_subtitle'.tr(),
      );
    }
    if (_notifier.record.isEmpty) {
      return EmptyState(
        icon: Icons.bar_chart_outlined,
        title: 'reports.no_results_title'.tr(),
        subtitle: 'reports.no_results_subtitle'.tr(),
      );
    }
    return RefreshIndicator(
      onRefresh: _notifier.load,
      color: AppColors.primaryLight,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _title(_notifier.teamName ?? ''),
          const SizedBox(height: 12),
          TeamRecordCard(record: _notifier.record),
          const SizedBox(height: 24),
          _title('reports.recent_form'.tr()),
          const SizedBox(height: 10),
          RecentFormChips(form: _notifier.recentForm),
          const SizedBox(height: 24),
          _title('reports.by_event'.tr()),
          const SizedBox(height: 10),
          ..._notifier.byEvent.map((entry) => _EventRecordTile(
                eventName: entry.eventName,
                record: entry.record,
              )),
        ],
      ),
    );
  }

  Widget _title(String text) => Text(
        text,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      );
}

class _EventRecordTile extends StatelessWidget {
  final String eventName;
  final TeamRecord record;

  const _EventRecordTile({required this.eventName, required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              eventName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            'reports.event_summary'.tr(namedArgs: {
              'won': '${record.won}',
              'drawn': '${record.drawn}',
              'lost': '${record.lost}',
            }),
            style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
