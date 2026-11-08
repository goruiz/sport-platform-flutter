import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/modules/courts/presentation/pages/court_detail_page.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/courts_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/court_model.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/sport_complexes/data/datasource/sport_complexes_service.dart';
import 'package:sport_platform/modules/sport_complexes/data/models/sport_complex_model.dart';
import 'package:sport_platform/modules/sport_complexes/domain/complex_overview.dart';
import 'package:sport_platform/shared/widgets/app_card.dart';
import 'package:sport_platform/shared/widgets/app_search_field.dart';
import 'package:sport_platform/shared/widgets/empty_state.dart';
import 'package:sport_platform/shared/widgets/error_retry.dart';

/// Las canchas y, para abrir el mapa desde cada una, los complejos a los que pertenecen.
class _CourtsData {
  final List<CourtModel> courts;

  /// Cada complejo con sus canchas, por id del complejo.
  final Map<String, ComplexOverview> complexesById;

  const _CourtsData({required this.courts, required this.complexesById});
}

class CourtsPage extends StatefulWidget {
  final MenuItemModel item;

  const CourtsPage({super.key, required this.item});

  @override
  State<CourtsPage> createState() => _CourtsPageState();
}

class _CourtsPageState extends State<CourtsPage> {
  late Future<_CourtsData> _courtsFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _courtsFuture = _loadCourts();
  }

  Future<_CourtsData> _loadCourts() async {
    // Las dos lecturas salen a la vez. Los complejos solo sirven para el enlace al mapa: si fallan, las canchas se
    // ven igual, solo que sin ese enlace.
    final courtsRead = getIt<CourtsService>().getAll();
    final complexesRead = getIt<SportComplexesService>().getAll().catchError((_) => const <SportComplexModel>[]);
    final courts = await courtsRead;
    final overviews = buildComplexOverviews(await complexesRead, courts);
    return _CourtsData(
      courts: courts,
      complexesById: {for (final overview in overviews) overview.complex.id: overview},
    );
  }

  Future<void> _reload() async {
    setState(() {
      _courtsFuture = _loadCourts();
    });
    await _courtsFuture;
  }

  void _openCourt(CourtModel court, _CourtsData data) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourtDetailPage(
          court: court,
          complex: data.complexesById[court.sportComplexId],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.localizedName),
        actions: [
          IconButton(
            onPressed: _reload,
            tooltip: 'common.retry'.tr(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<_CourtsData>(
        future: _courtsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryLight),
            );
          }
          if (snapshot.hasError) {
            return ErrorRetry(
              message: 'mobile.courts.load_error'.tr(),
              onRetry: _reload,
            );
          }
          final data = snapshot.data;
          final courts = data?.courts ?? const <CourtModel>[];
          final filtered = courts.where((court) {
            final query = _query.trim().toLowerCase();
            return query.isEmpty ||
                court.name.toLowerCase().contains(query) ||
                (court.sportComplexName?.toLowerCase().contains(query) ?? false) ||
                (court.location?.toLowerCase().contains(query) ?? false);
          }).toList()
            ..sort((a, b) => a.displayName
                .toLowerCase()
                .compareTo(b.displayName.toLowerCase()));

          if (data == null || courts.isEmpty) {
            return EmptyState(
              icon: Icons.location_off_outlined,
              title: 'mobile.courts.empty_title'.tr(),
              subtitle: 'mobile.courts.empty_subtitle'.tr(),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            color: AppColors.primaryLight,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: AppSearchField(
                      hint: 'mobile.courts.search_hint'.tr(),
                      onChanged: (value) => setState(() => _query = value),
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.search_off,
                      title: 'mobile.courts.filtered_empty_title'.tr(),
                      subtitle: 'mobile.courts.filtered_empty_subtitle'.tr(),
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _CourtCard(
                      court: filtered[index],
                      onTap: () => _openCourt(filtered[index], data),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CourtCard extends StatelessWidget {
  final CourtModel court;
  final VoidCallback onTap;

  const _CourtCard({required this.court, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final secondary = [
      if (court.sportComplexName?.isNotEmpty ?? false) court.sportComplexName,
      if (court.location?.isNotEmpty ?? false) court.location,
    ].join(' · ');
    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.sports_soccer,
              color: AppColors.primaryLight, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  court.name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                if (secondary.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    secondary,
                    style: const TextStyle(
                      color: AppColors.whiteSubtle,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (court.description?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 6),
                  Text(
                    court.description!,
                    style: const TextStyle(
                      color: AppColors.whiteSubtle,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.whiteSubtle),
        ],
      ),
    );
  }
}
