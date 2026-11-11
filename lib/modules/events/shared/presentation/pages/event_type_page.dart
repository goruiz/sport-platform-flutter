import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/events/shared/data/providers/events_notifier.dart';
import 'package:sport_platform/modules/events/shared/presentation/widgets/event_card.dart';
import 'package:sport_platform/shared/widgets/empty_state.dart';
import 'package:sport_platform/shared/widgets/error_retry.dart';

/// Página tabbed (Mis eventos / Todos) reutilizable para cualquier tipo de evento. Solo lista: el organizador
/// crea y gestiona los eventos desde el panel.
/// Requiere un [EventsNotifier] provisto por el widget padre vía [ChangeNotifierProvider].
class EventTypePage extends StatefulWidget {
  final MenuItemModel menuItem;
  final String translationPrefix;
  final IconData typeIcon;
  final void Function(EventModel event)? onEventTap;

  const EventTypePage({
    super.key,
    required this.menuItem,
    required this.translationPrefix,
    this.typeIcon = Icons.sports,
    this.onEventTap,
  });

  @override
  State<EventTypePage> createState() => _EventTypePageState();
}

class _EventTypePageState extends State<EventTypePage> {
  /// La pestaña «Todos»: el jugador ve primero todo lo que su organización ofrece.
  static const _allEventsTabIndex = 1;

  String get _prefix => widget.translationPrefix;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventsNotifier>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: _allEventsTabIndex,
      child: Scaffold(
        backgroundColor: AppColors.backgroundEnd,
        appBar: AppBar(
          backgroundColor: AppColors.primaryDark,
          title: Text(
            widget.menuItem.localizedName,
            style: const TextStyle(color: AppColors.white),
          ),
          iconTheme: const IconThemeData(color: AppColors.white),
          elevation: 0,
          actions: [
            Consumer<EventsNotifier>(
              builder: (context, notifier, child) => IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.white),
                onPressed: notifier.loading
                    ? null
                    : () => notifier.load(force: true),
                tooltip: '$_prefix.retry'.tr(),
              ),
            ),
          ],
          bottom: TabBar(
            labelColor: AppColors.primaryLight,
            unselectedLabelColor: AppColors.whiteSubtle,
            indicatorColor: AppColors.primaryLight,
            dividerColor: AppColors.inputBorder,
            tabs: [
              Tab(text: '$_prefix.tab_mine'.tr()),
              Tab(text: '$_prefix.tab_all'.tr()),
            ],
          ),
        ),
        body: Consumer<EventsNotifier>(
          builder: (context, notifier, child) => _buildBody(notifier),
        ),
      ),
    );
  }

  Widget _buildBody(EventsNotifier notifier) {
    if (notifier.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryLight),
      );
    }

    if (notifier.error != null) {
      final errorMsg = '$_prefix.error_load'.tr();
      return ErrorRetry(message: errorMsg, onRetry: notifier.load);
    }

    return TabBarView(
      children: [
        _EventListView(
          events: notifier.mine,
          typeIcon: widget.typeIcon,
          onRefresh: () => notifier.load(force: true),
          emptyTitle: '$_prefix.no_items_mine'.tr(),
          emptySubtitle: '$_prefix.no_items_mine_subtitle'.tr(),
          onEventTap: widget.onEventTap,
        ),
        _EventListView(
          events: notifier.all.toList(),
          typeIcon: widget.typeIcon,
          onRefresh: () => notifier.load(force: true),
          emptyTitle: '$_prefix.no_items'.tr(),
          emptySubtitle: '$_prefix.no_items_subtitle'.tr(),
          onEventTap: widget.onEventTap,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _EventListView extends StatelessWidget {
  final List<EventModel> events;
  final IconData typeIcon;
  final Future<void> Function() onRefresh;
  final String emptyTitle;
  final String emptySubtitle;
  final void Function(EventModel event)? onEventTap;

  const _EventListView({
    required this.events,
    required this.typeIcon,
    required this.onRefresh,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return EmptyState(
        title: emptyTitle,
        subtitle: emptySubtitle,
        icon: typeIcon,
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primaryLight,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 100),
        itemCount: events.length,
        itemBuilder: (_, i) {
          final event = events[i];
          return EventCard(
            event: event,
            typeIcon: typeIcon,
            onTap: onEventTap != null ? () => onEventTap!(event) : null,
          );
        },
      ),
    );
  }
}
