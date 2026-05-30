import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/events/shared/data/providers/events_notifier.dart';
import 'package:sport_platform/modules/events/shared/presentation/widgets/event_card.dart';
import 'package:sport_platform/modules/events/shared/presentation/widgets/event_form_sheet.dart';
import 'package:sport_platform/shared/widgets/confirmation_dialog.dart';
import 'package:sport_platform/shared/widgets/empty_state.dart';
import 'package:sport_platform/shared/widgets/error_retry.dart';

/// Página tabbed (Mis eventos / Todos) reutilizable para cualquier tipo de evento.
/// Requiere un [EventsNotifier] provisto por el widget padre vía [ChangeNotifierProvider].
class EventTypePage extends StatefulWidget {
  final MenuItemModel menuItem;
  final String translationPrefix;
  final IconData typeIcon;
  final void Function(EventModel event, bool isOwner)? onEventTap;

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
  String get _prefix => widget.translationPrefix;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventsNotifier>().load();
    });
  }

  Future<void> _openCreate() async {
    final notifier = context.read<EventsNotifier>();
    await EventFormSheet.show(
      context: context,
      translationPrefix: _prefix,
      onSave: (data) async {
        await notifier.create(data);
        if (mounted) _showSnack('$_prefix.success_created'.tr());
      },
    );
    if (mounted) notifier.silentReload();
  }

  Future<void> _openEdit(EventModel event) async {
    final notifier = context.read<EventsNotifier>();
    await EventFormSheet.show(
      context: context,
      translationPrefix: _prefix,
      event: event,
      onSave: (data) async {
        await notifier.update(event.id, data);
        if (mounted) _showSnack('$_prefix.success_updated'.tr());
      },
    );
  }

  Future<void> _confirmDelete(EventModel event) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: '$_prefix.delete_item'.tr(),
      content: '$_prefix.confirm_delete'.tr(args: [event.name]),
      confirmLabel: '$_prefix.delete'.tr(),
      cancelLabel: '$_prefix.cancel'.tr(),
    );
    if (!confirmed || !mounted) return;
    try {
      await context.read<EventsNotifier>().delete(event.id);
      if (mounted) _showSnack('$_prefix.success_deleted'.tr());
    } catch (_) {
      if (mounted) _showSnack('$_prefix.error_delete'.tr(), isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundEnd,
        appBar: AppBar(
          backgroundColor: AppColors.primaryDark,
          title: Text(
            widget.menuItem.displayName.tr(),
            style: const TextStyle(color: AppColors.white),
          ),
          iconTheme: const IconThemeData(color: AppColors.white),
          elevation: 0,
          actions: [
            Consumer<EventsNotifier>(
              builder: (context, notifier, child) => IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.white),
                onPressed: notifier.loading ? null : notifier.load,
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
        floatingActionButton: FloatingActionButton(
          onPressed: _openCreate,
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.white,
          tooltip: '$_prefix.new_item'.tr(),
          child: const Icon(Icons.add),
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
          myEventIds: notifier.myIds,
          typeIcon: widget.typeIcon,
          onRefresh: notifier.load,
          onEdit: _openEdit,
          onDelete: _confirmDelete,
          emptyTitle: '$_prefix.no_items_mine'.tr(),
          emptySubtitle: '$_prefix.no_items_mine_subtitle'.tr(),
          onAdd: _openCreate,
          onEventTap: widget.onEventTap,
        ),
        _EventListView(
          events: notifier.all.toList(),
          myEventIds: notifier.myIds,
          typeIcon: widget.typeIcon,
          onRefresh: notifier.load,
          onEdit: _openEdit,
          onDelete: _confirmDelete,
          emptyTitle: '$_prefix.no_items'.tr(),
          emptySubtitle: '$_prefix.no_items_subtitle'.tr(),
          onAdd: _openCreate,
          onEventTap: widget.onEventTap,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _EventListView extends StatelessWidget {
  final List<EventModel> events;
  final Set<String> myEventIds;
  final IconData typeIcon;
  final Future<void> Function() onRefresh;
  final void Function(EventModel) onEdit;
  final void Function(EventModel) onDelete;
  final String emptyTitle;
  final String emptySubtitle;
  final VoidCallback onAdd;
  final void Function(EventModel event, bool isOwner)? onEventTap;

  const _EventListView({
    required this.events,
    required this.myEventIds,
    required this.typeIcon,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onAdd,
    this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return EmptyState(
        title: emptyTitle,
        subtitle: emptySubtitle,
        icon: typeIcon,
        onAdd: onAdd,
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
          final isOwned = myEventIds.contains(event.id);
          return EventCard(
            event: event,
            typeIcon: typeIcon,
            onTap: onEventTap != null ? () => onEventTap!(event, isOwned) : null,
            onEdit: isOwned ? () => onEdit(event) : null,
            onDelete: isOwned ? () => onDelete(event) : null,
          );
        },
      ),
    );
  }
}
