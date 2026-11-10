import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/court_model.dart';
import 'package:sport_platform/shared/widgets/app_card.dart';

/// Un complejo con sus canchas dentro, de un vistazo: el encabezado dice cuál es y dónde queda (y, si se toca, abre el
/// complejo con su mapa) y debajo va cada cancha, que se toca para abrirla. Sin [onTapHeader] el encabezado solo rotula (es
/// el caso de las canchas que no son de ningún complejo).
class ComplexSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;

  /// La dirección o referencia del complejo.
  final String? location;

  /// Un aviso bajo la dirección (por ejemplo, que el complejo no tiene ubicación en el mapa).
  final String? note;
  final VoidCallback? onTapHeader;
  final List<CourtModel> courts;
  final ValueChanged<CourtModel> onTapCourt;

  const ComplexSectionCard({
    super.key,
    required this.icon,
    required this.title,
    this.location,
    this.note,
    this.onTapHeader,
    required this.courts,
    required this.onTapCourt,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: AppSpacing.sm - 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Divider(height: 1, color: AppColors.inputBorder),
          if (courts.isEmpty) _buildNoCourts() else for (final court in courts) _CourtRow(court: court, onTap: () => onTapCourt(court)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return InkWell(
      onTap: onTapHeader,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primaryLight, size: 26),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.cardTitle.copyWith(fontSize: 16)),
                  if (location?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 4),
                    Text(location!, style: AppTextStyles.caption),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'mobile.complexes.courts_count'.tr(namedArgs: {'count': '${courts.length}'}),
                    style: AppTextStyles.caption.copyWith(color: AppColors.primaryLight),
                  ),
                  if (note?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 2),
                    Text(note!, style: AppTextStyles.caption),
                  ],
                ],
              ),
            ),
            if (onTapHeader != null) const Icon(Icons.chevron_right, color: AppColors.whiteSubtle),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCourts() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Text('mobile.complexes.no_courts'.tr(), style: AppTextStyles.caption),
    );
  }
}

/// Una cancha dentro de la tarjeta de su complejo.
class _CourtRow extends StatelessWidget {
  final CourtModel court;
  final VoidCallback onTap;

  const _CourtRow({required this.court, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.sports_soccer, color: AppColors.primaryLight, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(court.name, style: AppTextStyles.body.copyWith(color: AppColors.white)),
                  if (court.description?.isNotEmpty ?? false)
                    Text(court.description!, style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.whiteSubtle),
          ],
        ),
      ),
    );
  }
}
