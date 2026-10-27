import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/courts_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/court_model.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/shared/widgets/empty_state.dart';
import 'package:sport_platform/shared/widgets/error_retry.dart';

class CourtsPage extends StatefulWidget {
  final MenuItemModel item;

  const CourtsPage({super.key, required this.item});

  @override
  State<CourtsPage> createState() => _CourtsPageState();
}

class _CourtsPageState extends State<CourtsPage> {
  late Future<List<CourtModel>> _courtsFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _courtsFuture = getIt<CourtsService>().getAll();
  }

  Future<void> _reload() async {
    setState(() => _courtsFuture = getIt<CourtsService>().getAll());
    await _courtsFuture;
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
            onPressed: _reload,
            tooltip: 'common.retry'.tr(),
            icon: const Icon(Icons.refresh, color: AppColors.white),
          ),
        ],
      ),
      body: FutureBuilder<List<CourtModel>>(
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
          final courts = snapshot.data ?? const <CourtModel>[];
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

          if (courts.isEmpty) {
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
                    child: TextField(
                      onChanged: (value) => setState(() => _query = value),
                      style: const TextStyle(color: AppColors.white),
                      decoration: InputDecoration(
                        hintText: 'mobile.courts.search_hint'.tr(),
                        hintStyle:
                            const TextStyle(color: AppColors.whiteSubtle),
                        prefixIcon: const Icon(Icons.search,
                            color: AppColors.whiteSubtle),
                        filled: true,
                        fillColor: AppColors.inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.inputBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.inputBorder),
                        ),
                      ),
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
                    itemBuilder: (context, index) =>
                        _CourtCard(court: filtered[index]),
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

  const _CourtCard({required this.court});

  @override
  Widget build(BuildContext context) {
    final secondary = [
      if (court.sportComplexName?.isNotEmpty ?? false) court.sportComplexName,
      if (court.location?.isNotEmpty ?? false) court.location,
    ].join(' · ');
    return Container(
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
        ],
      ),
    );
  }
}
