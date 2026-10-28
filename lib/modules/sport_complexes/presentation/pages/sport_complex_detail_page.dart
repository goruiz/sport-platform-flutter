import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/sport_complexes/domain/complex_overview.dart';
import 'package:sport_platform/modules/sport_complexes/presentation/widgets/complex_map.dart';

/// Un complejo: dónde queda (con su mapa, si el organizador lo marcó) y sus canchas.
class SportComplexDetailPage extends StatelessWidget {
  final ComplexOverview overview;

  const SportComplexDetailPage({super.key, required this.overview});

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
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle('mobile.complexes.location_title'.tr()),
          if (complex.hasMapPosition)
            ComplexMap(latitude: complex.latitude!, longitude: complex.longitude!)
          else
            _Hint('mobile.complexes.no_location_detail'.tr()),
          if (complex.location?.isNotEmpty ?? false) ...[
            const SizedBox(height: 10),
            _Line(icon: Icons.place_outlined, text: complex.location!),
          ],
          if (complex.description?.isNotEmpty ?? false) ...[
            const SizedBox(height: 6),
            _Line(icon: Icons.info_outline, text: complex.description!),
          ],
          const SizedBox(height: 24),
          _SectionTitle('mobile.complexes.courts_title'.tr()),
          if (overview.courts.isEmpty)
            _Hint('mobile.complexes.no_courts'.tr())
          else
            for (final court in overview.courts)
              _Line(
                icon: Icons.sports_soccer,
                text: court.name,
                detail: court.description,
              ),
        ],
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
      padding: const EdgeInsets.only(bottom: 10),
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
    return Text(text, style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 13));
  }
}

class _Line extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? detail;

  const _Line({required this.icon, required this.text, this.detail});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryLight, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(color: AppColors.white, fontSize: 14)),
                if (detail?.isNotEmpty ?? false)
                  Text(
                    detail!,
                    style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
