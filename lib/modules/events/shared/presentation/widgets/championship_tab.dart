import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/core/constants/locale_keys.g.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/events/shared/data/datasource/championship_service.dart';
import 'package:sport_platform/modules/events/shared/data/models/championship_model.dart';
import 'package:sport_platform/modules/events/shared/presentation/utils/championship_labels.dart';
import 'package:sport_platform/modules/events/shared/presentation/widgets/championship_round_card.dart';
import 'package:sport_platform/modules/events/shared/presentation/widgets/championship_summary_card.dart';
import 'package:sport_platform/modules/events/shared/presentation/widgets/championship_table_card.dart';
import 'package:sport_platform/shared/widgets/empty_state.dart';
import 'package:sport_platform/shared/widgets/error_retry.dart';

/// El campeonato de un evento según su formato: la etapa en que va, las tablas de puntos y la llave.
/// Solo se lee: las fases las genera el organizador desde el panel.
class ChampionshipTab extends StatefulWidget {
  final String eventId;

  const ChampionshipTab({super.key, required this.eventId});

  @override
  State<ChampionshipTab> createState() => _ChampionshipTabState();
}

class _ChampionshipTabState extends State<ChampionshipTab>
    with AutomaticKeepAliveClientMixin {
  final ChampionshipService _service = getIt<ChampionshipService>();
  late Future<ChampionshipModel> _championship;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _championship = _service.getByEvent(widget.eventId);
  }

  Future<void> _reload() async {
    setState(() {
      _championship = _service.getByEvent(widget.eventId);
    });
    await _championship;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    context.locale;
    return FutureBuilder<ChampionshipModel>(
      future: _championship,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return ErrorRetry(
            message: LocaleKeys.championship_load_error.tr(),
            onRetry: _reload,
          );
        }
        final championship = snapshot.data!;
        if (!championship.hasChampionship) {
          return EmptyState(
            icon: Icons.account_tree_outlined,
            title: LocaleKeys.championship_none_title.tr(),
            subtitle: LocaleKeys.championship_none_subtitle.tr(),
          );
        }
        return RefreshIndicator(
          onRefresh: _reload,
          color: AppColors.primaryLight,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.listBottom),
            children: _buildSections(championship),
          ),
        );
      },
    );
  }

  List<Widget> _buildSections(ChampionshipModel championship) {
    final advancingRows = advancingRowsOf(championship);
    final eliminationRounds = championship.eliminationRounds;
    final hasNothingToShow = championship.tables.isEmpty && eliminationRounds.isEmpty;
    return [
      ChampionshipSummaryCard(championship: championship),
      const SizedBox(height: AppSpacing.xl),
      if (hasNothingToShow) _buildNothingGenerated(),
      for (final table in championship.tables) ...[
        ChampionshipTableCard(table: table, advancingRows: advancingRows),
        const SizedBox(height: AppSpacing.xl),
      ],
      if (eliminationRounds.isNotEmpty) ...[
        _buildSectionTitle(LocaleKeys.championship_bracket.tr()),
        for (final round in eliminationRounds) ...[
          ChampionshipRoundCard(round: round, championship: championship),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    ];
  }

  Widget _buildNothingGenerated() => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Text(
          LocaleKeys.championship_nothing_generated.tr(),
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMuted,
        ),
      );

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.snug, left: AppSpacing.xs),
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.primaryLight,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      );
}
