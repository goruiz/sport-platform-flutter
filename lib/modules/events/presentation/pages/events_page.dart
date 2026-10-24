import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/network/response_parser.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/events/event_types/leagues/presentation/pages/league_detail_page.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/events/shared/presentation/widgets/event_card.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/shared/widgets/empty_state.dart';
import 'package:sport_platform/shared/widgets/error_retry.dart';

class EventsPage extends StatefulWidget {
  final MenuItemModel item;

  const EventsPage({super.key, required this.item});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final _client = DioClient();
  late Future<List<EventModel>> _eventsFuture;
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _eventsFuture = _loadEvents();
  }

  Future<List<EventModel>> _loadEvents() async {
    final response = await _client.get(ApiEndpoints.events);
    final events =
        ResponseParser.toList(response.data)
            .map((item) => EventModel.fromJson(item as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate));
    return events;
  }

  Future<void> _refresh() async {
    setState(() => _eventsFuture = _loadEvents());
    await _eventsFuture;
  }

  void _openEvent(EventModel event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LeagueDetailPage(event: event, isOwner: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Scaffold(
      backgroundColor: AppColors.backgroundEnd,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: Text(
          widget.item.displayName.tr(),
          style: const TextStyle(color: AppColors.white),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
        actions: [
          IconButton(
            onPressed: () => setState(() => _eventsFuture = _loadEvents()),
            icon: const Icon(Icons.refresh, color: AppColors.white),
            tooltip: 'common.retry'.tr(),
          ),
        ],
      ),
      body: FutureBuilder<List<EventModel>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryLight),
            );
          }
          if (snapshot.hasError) {
            return ErrorRetry(
              message: 'mobile.events.load_error'.tr(),
              onRetry: () => setState(() => _eventsFuture = _loadEvents()),
            );
          }
          final events = snapshot.data ?? const <EventModel>[];
          if (events.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.primaryLight,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.65,
                    child: EmptyState(
                      icon: Icons.emoji_events_outlined,
                      title: 'mobile.events.empty_title'.tr(),
                      subtitle: 'mobile.events.empty_subtitle'.tr(),
                    ),
                  ),
                ],
              ),
            );
          }

          final types =
              events
                  .map((event) => event.eventTypeName?.trim())
                  .whereType<String>()
                  .where((type) => type.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
          final filtered = _selectedType == null
              ? events
              : events
                    .where((event) => event.eventTypeName == _selectedType)
                    .toList();

          return RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primaryLight,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (types.isNotEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 58,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildTypeChip('mobile.events.all'.tr(), null),
                          ...types.map((type) => _buildTypeChip(type, type)),
                        ],
                      ),
                    ),
                  ),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.filter_list_off,
                      title: 'mobile.events.filtered_empty_title'.tr(),
                      subtitle: 'mobile.events.filtered_empty_subtitle'.tr(),
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => EventCard(
                      event: filtered[index],
                      typeIcon: Icons.emoji_events_outlined,
                      onTap: () => _openEvent(filtered[index]),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeChip(String label, String? type) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: FilterChip(
      label: Text(label),
      selected: _selectedType == type,
      onSelected: (_) => setState(() => _selectedType = type),
      selectedColor: AppColors.primaryLight.withValues(alpha: 0.2),
      backgroundColor: AppColors.inputFill,
      checkmarkColor: AppColors.primaryLight,
      labelStyle: TextStyle(
        color: _selectedType == type
            ? AppColors.primaryLight
            : AppColors.whiteSubtle,
      ),
      side: BorderSide(
        color: _selectedType == type
            ? AppColors.primaryLight
            : AppColors.inputBorder,
      ),
    ),
  );
}
