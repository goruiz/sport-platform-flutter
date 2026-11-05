import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/core/utils/date_formatters.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/enums/match_status.dart';
import 'package:sport_platform/shared/widgets/initials_avatar.dart';

/// El «marcador» de un partido: el escudo y el nombre de cada equipo y, en medio, lo que más importa en ese
/// momento: el resultado si ya se jugó, la hora si aún no, o «VS» si el partido no tiene fecha firme.
class MatchScoreboard extends StatelessWidget {
  final MatchModel match;
  final String homeName;
  final String awayName;

  /// Más grande, para el detalle de un partido y para el partido destacado del inicio.
  final bool large;

  /// Escribe el día («Hoy», «mié, 12 nov») bajo el marcador o la hora. Se apaga cuando la lista ya agrupa por día.
  final bool showDay;

  const MatchScoreboard({
    super.key,
    required this.match,
    required this.homeName,
    required this.awayName,
    this.large = false,
    this.showDay = true,
  });

  /// Un partido aplazado, suspendido o cancelado no tiene una hora en la que fiarse: se muestra «VS».
  static bool hasFirmSchedule(MatchStatus status) => switch (status) {
        MatchStatus.postponed ||
        MatchStatus.suspended ||
        MatchStatus.cancelled =>
          false,
        _ => true,
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _TeamColumn(name: homeName, large: large)),
        SizedBox(
          width: large ? 118 : 96,
          child: _buildCenter(context),
        ),
        Expanded(child: _TeamColumn(name: awayName, large: large)),
      ],
    );
  }

  Widget _buildCenter(BuildContext context) {
    // El centro queda a la altura del escudo, no del nombre que va debajo.
    final crestHeight = large ? 60.0 : 48.0;
    return SizedBox(
      height: crestHeight + (large ? 40 : 36),
      child: Padding(
        padding: EdgeInsets.only(top: large ? 4 : 2),
        child: Column(
          children: [
            _buildMainLabel(),
            if (showDay && hasFirmSchedule(match.status)) ...[
              const SizedBox(height: 2),
              Text(
                DateFormatters.friendlyDay(
                  match.matchDate,
                  context.locale.languageCode,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption,
              ),
            ],
            if (match.status == MatchStatus.inProgress) ...[
              const SizedBox(height: 4),
              const _LiveDot(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMainLabel() {
    final fontSize = large ? 34.0 : 28.0;
    if (match.hasScore) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '${match.homeScore} – ${match.awayScore}',
          style: AppTextStyles.score.copyWith(fontSize: fontSize),
        ),
      );
    }
    if (hasFirmSchedule(match.status)) {
      return Text(
        DateFormatters.time(match.matchDate),
        style: AppTextStyles.score.copyWith(
          fontSize: fontSize - 4,
          color: AppColors.primaryLight,
        ),
      );
    }
    return Text(
      'VS',
      style: AppTextStyles.score.copyWith(
        fontSize: fontSize - 8,
        color: AppColors.whiteSubtle,
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  final String name;
  final bool large;

  const _TeamColumn({required this.name, required this.large});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InitialsAvatar(name: name, size: large ? 60 : 48),
        const SizedBox(height: AppSpacing.sm),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.cardTitle.copyWith(fontSize: large ? 15 : 13.5),
        ),
      ],
    );
  }
}

/// El punto que parpadea junto a «En juego».
class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Quien pidió «reducir movimiento» en el sistema ve el punto fijo, sin parpadeo.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: Tween<double>(begin: 0.35, end: 1).animate(_controller),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.warning,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          'leagues.match_status_in_progress'.tr(),
          style: const TextStyle(
            color: AppColors.warning,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
