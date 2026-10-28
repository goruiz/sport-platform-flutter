import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/courts_service.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/sport_complexes/data/datasource/sport_complexes_service.dart';
import 'package:sport_platform/modules/sport_complexes/domain/complex_overview.dart';
import 'package:sport_platform/modules/sport_complexes/presentation/pages/sport_complex_detail_page.dart';
import 'package:sport_platform/shared/widgets/empty_state.dart';
import 'package:sport_platform/shared/widgets/error_retry.dart';

/// Los complejos deportivos de la organización del jugador, con su dirección y cuántas canchas tienen.
class SportComplexesPage extends StatefulWidget {
  final MenuItemModel item;

  const SportComplexesPage({super.key, required this.item});

  @override
  State<SportComplexesPage> createState() => _SportComplexesPageState();
}

class _SportComplexesPageState extends State<SportComplexesPage> {
  late Future<List<ComplexOverview>> _overviewsFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _overviewsFuture = _loadOverviews();
  }

  Future<List<ComplexOverview>> _loadOverviews() async {
    // Las dos lecturas salen a la vez; se espera cada una por separado para conservar su tipo.
    final complexes = getIt<SportComplexesService>().getAll();
    final courts = getIt<CourtsService>().getAll();
    return buildComplexOverviews(await complexes, await courts);
  }

  Future<void> _reload() async {
    setState(() => _overviewsFuture = _loadOverviews());
    await _overviewsFuture;
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Scaffold(
      backgroundColor: AppColors.backgroundEnd,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: Text(
          widget.item.localizedName,
          style: const TextStyle(color: AppColors.white),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
        actions: [
          IconButton(
            onPressed: _reload,
            tooltip: 'common.retry'.tr(),
            icon: const Icon(Icons.refresh, color: AppColors.white),
          ),
        ],
      ),
      body: FutureBuilder<List<ComplexOverview>>(
        future: _overviewsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryLight),
            );
          }
          if (snapshot.hasError) {
            return ErrorRetry(
              message: 'mobile.complexes.load_error'.tr(),
              onRetry: _reload,
            );
          }
          return _buildContent(snapshot.data ?? const []);
        },
      ),
    );
  }

  Widget _buildContent(List<ComplexOverview> overviews) {
    if (overviews.isEmpty) {
      return EmptyState(
        icon: Icons.stadium_outlined,
        title: 'mobile.complexes.empty_title'.tr(),
        subtitle: 'mobile.complexes.empty_subtitle'.tr(),
      );
    }
    final visible = filterComplexOverviews(overviews, _query);
    return RefreshIndicator(
      onRefresh: _reload,
      color: AppColors.primaryLight,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildSearchField()),
          if (visible.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.search_off,
                title: 'mobile.complexes.filtered_empty_title'.tr(),
                subtitle: 'mobile.complexes.filtered_empty_subtitle'.tr(),
              ),
            )
          else
            SliverList.builder(
              itemCount: visible.length,
              itemBuilder: (context, index) => _ComplexCard(overview: visible[index]),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        onChanged: (value) => setState(() => _query = value),
        style: const TextStyle(color: AppColors.white),
        decoration: InputDecoration(
          hintText: 'mobile.complexes.search_hint'.tr(),
          hintStyle: const TextStyle(color: AppColors.whiteSubtle),
          prefixIcon: const Icon(Icons.search, color: AppColors.whiteSubtle),
          filled: true,
          fillColor: AppColors.inputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
        ),
      ),
    );
  }
}

class _ComplexCard extends StatelessWidget {
  final ComplexOverview overview;

  const _ComplexCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    final complex = overview.complex;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SportComplexDetailPage(overview: overview),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.stadium_outlined, color: AppColors.primaryLight, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    complex.name,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (complex.location?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 5),
                    Text(
                      complex.location!,
                      style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'mobile.complexes.courts_count'.tr(
                      namedArgs: {'count': '${overview.courts.length}'},
                    ),
                    style: const TextStyle(color: AppColors.primaryLight, fontSize: 12),
                  ),
                  if (!complex.hasMapPosition) ...[
                    const SizedBox(height: 4),
                    Text(
                      'mobile.complexes.no_location'.tr(),
                      style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 12),
                    ),
                  ],
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
