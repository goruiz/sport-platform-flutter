import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/core/constants/locale_keys.g.dart';
import 'package:sport_platform/core/services/external_launcher.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/utils/external_links.dart';
import 'package:sport_platform/modules/courts/presentation/pages/court_detail_page.dart';
import 'package:sport_platform/modules/courts/data/models/court_model.dart';
import 'package:sport_platform/modules/sport_complexes/domain/complex_overview.dart';
import 'package:sport_platform/modules/sport_complexes/presentation/widgets/complex_map.dart';
import 'package:sport_platform/shared/widgets/app_snackbar.dart';

/// Un complejo: dónde queda (con su mapa, si el organizador lo marcó) y sus canchas.
class SportComplexDetailPage extends StatelessWidget {
  final ComplexOverview overview;

  const SportComplexDetailPage({super.key, required this.overview});

  /// El detalle de una cancha del complejo (sin el enlace de vuelta al complejo: ya se viene de él).
  void _openCourt(BuildContext context, CourtModel court) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CourtDetailPage(court: court)),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    final complex = overview.complex;
    return Scaffold(
      backgroundColor: AppColors.backgroundEnd,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: Text(complex.name, style: const TextStyle(color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _SectionTitle(LocaleKeys.mobile_complexes_location_title.tr()),
          if (complex.hasMapPosition) ...[
            ComplexMap(latitude: complex.latitude!, longitude: complex.longitude!),
            const SizedBox(height: AppSpacing.snug),
            _DirectionsButton(latitude: complex.latitude!, longitude: complex.longitude!),
          ] else
            _Hint(LocaleKeys.mobile_complexes_no_location_detail.tr()),
          if (complex.location?.isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.snug),
            _Line(icon: Icons.place_outlined, text: complex.location!),
          ],
          if (complex.description?.isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.tight),
            _Line(icon: Icons.info_outline, text: complex.description!),
          ],
          const SizedBox(height: AppSpacing.xxl),
          _SectionTitle(LocaleKeys.mobile_complexes_courts_title.tr()),
          if (overview.courts.isEmpty)
            _Hint(LocaleKeys.mobile_complexes_no_courts.tr())
          else
            for (final court in overview.courts)
              _Line(
                icon: Icons.sports_soccer,
                text: court.name,
                detail: court.description,
                onTap: () => _openCourt(context, court),
              ),
        ],
      ),
    );
  }
}

/// Abre la ruta hasta el complejo en la aplicación de mapas del dispositivo.
class _DirectionsButton extends StatelessWidget {
  final double latitude;
  final double longitude;

  const _DirectionsButton({required this.latitude, required this.longitude});

  Future<void> _open(BuildContext context) async {
    final opened = await ExternalLauncher.open(
      ExternalLinks.directionsTo(latitude: latitude, longitude: longitude),
    );
    if (!opened && context.mounted) {
      AppSnackbar.error(context, LocaleKeys.mobile_complexes_directions_error.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => _open(context),
        icon: const Icon(Icons.directions_outlined),
        label: Text(LocaleKeys.mobile_complexes_directions.tr()),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.snug),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;

  const _Hint(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.secondary);
  }
}

class _Line extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? detail;

  /// Si se da, la línea se puede tocar y lo indica con una flecha.
  final VoidCallback? onTap;

  const _Line({required this.icon, required this.text, this.detail, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.tight),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primaryLight, size: 20),
            const SizedBox(width: AppSpacing.snug),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text, style: AppTextStyles.body),
                  if (detail?.isNotEmpty ?? false)
                    Text(
                      detail!,
                      style: AppTextStyles.footnote,
                    ),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.chevron_right, color: AppColors.whiteSubtle),
          ],
        ),
      ),
    );
  }
}
