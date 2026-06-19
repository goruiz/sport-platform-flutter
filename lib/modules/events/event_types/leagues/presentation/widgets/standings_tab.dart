import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/standings_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/standing_model.dart';
import 'package:sport_platform/shared/widgets/empty_state.dart';

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
        final standings = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                _buildHeader(),
                ...standings.map((s) => _buildRow(s.position, s)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.primaryDark,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Row(
        children: [
          _HeaderCell('#', width: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'leagues.standings_col_team'.tr(),
              style: const TextStyle(
                color: AppColors.whiteSubtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          _HeaderCell('leagues.standings_col_played'.tr(), width: 30),
          _HeaderCell('leagues.standings_col_won'.tr(), width: 28),
          _HeaderCell('leagues.standings_col_drawn'.tr(), width: 28),
          _HeaderCell('leagues.standings_col_lost'.tr(), width: 28),
          _HeaderCell(
            'leagues.standings_col_pts'.tr(),
            width: 36,
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(int pos, StandingModel standing) {
    final isTop3 = pos <= 3;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.sheetBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.inputBorder, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
      child: Row(
        children: [
          _PosBadge(pos: pos),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              standing.teamName,
              style: TextStyle(
                color: isTop3 ? AppColors.white : AppColors.whiteSubtle,
                fontSize: 13,
                fontWeight: isTop3 ? FontWeight.w600 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _DataCell('${standing.played}', width: 30, color: AppColors.whiteSubtle),
          _DataCell('${standing.won}', width: 28, color: AppColors.success),
          _DataCell('${standing.drawn}', width: 28, color: AppColors.whiteSubtle),
          _DataCell('${standing.lost}', width: 28, color: AppColors.error),
          _DataCell(
            '${standing.points}',
            width: 36,
            color: AppColors.primaryLight,
            bold: true,
            fontSize: 15,
          ),
        ],
      ),
    );
  }
}

// ── Private helpers ───────────────────────────────────────────────────────────

class _HeaderCell extends StatelessWidget {
  final String text;
  final double width;
  final bool highlight;

  const _HeaderCell(this.text, {required this.width, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: highlight ? AppColors.primaryLight : AppColors.whiteSubtle,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  final double width;
  final Color color;
  final bool bold;
  final double fontSize;

  const _DataCell(
    this.text, {
    required this.width,
    required this.color,
    this.bold = false,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _PosBadge extends StatelessWidget {
  final int pos;
  const _PosBadge({required this.pos});

  static const _gold = Color(0xFFFFD700);
  static const _silver = Color(0xFFB0B8C1);
  static const _bronze = Color(0xFFCD7F32);

  @override
  Widget build(BuildContext context) {
    final Color? badgeColor = switch (pos) {
      1 => _gold,
      2 => _silver,
      3 => _bronze,
      _ => null,
    };

    if (badgeColor != null) {
      return SizedBox(
        width: 28,
        child: Center(
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$pos',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 28,
      child: Text(
        '$pos',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 13),
      ),
    );
  }
}
