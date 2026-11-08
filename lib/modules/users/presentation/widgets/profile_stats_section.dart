import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/modules/rankings/data/models/player_stats_model.dart';
import 'package:sport_platform/modules/rankings/presentation/widgets/my_stats_card.dart';
import 'package:sport_platform/modules/users/presentation/providers/profile_summary_notifier.dart';
import 'package:sport_platform/modules/users/presentation/widgets/profile_section.dart';
import 'package:sport_platform/shared/widgets/skeleton_box.dart';

/// Las estadísticas personales en el perfil: goles, asistencias, tarjetas y faltas sumados en todos los eventos
/// del equipo del jugador.
class ProfileStatsSection extends StatelessWidget {
  final SummaryStatus status;
  final PlayerStatsModel? stats;
  final VoidCallback onRetry;

  const ProfileStatsSection({
    super.key,
    required this.status,
    required this.stats,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    context.locale;
    final totals = stats;
    return switch (status) {
      SummaryStatus.loading => const SkeletonBox(height: 110),
      SummaryStatus.failed => _buildMessage('mobile.profile.stats_error'.tr(), onRetry: onRetry),
      SummaryStatus.ready when totals == null => _buildMessage('mobile.profile.stats_empty'.tr()),
      SummaryStatus.ready => MyStatsCard(
        stats: totals!,
        subtitle: 'mobile.profile.stats_caption'.tr(),
        margin: EdgeInsets.zero,
      ),
    };
  }

  Widget _buildMessage(String message, {VoidCallback? onRetry}) {
    return ProfileSection(
      title: 'rankings.my_stats.title'.tr(),
      children: [ProfileMessageRow(message: message, onRetry: onRetry)],
    );
  }
}
