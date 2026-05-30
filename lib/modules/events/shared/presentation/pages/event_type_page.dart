import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/events/shared/data/datasource/event_service.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/modules/events/shared/presentation/widgets/event_card.dart';
import 'package:sport_platform/modules/events/shared/presentation/widgets/event_form_sheet.dart';

/// Reusable tabbed page (Mine / All) for any event-type module.
///
/// To add a new event type (e.g. tournaments), create a subclass of
/// [EventService] and wrap this widget — no logic changes needed here.
class EventTypePage extends StatefulWidget {
  final MenuItemModel menuItem;
  final EventService service;
  final String translationPrefix;
  final IconData typeIcon;
  final void Function(EventModel event, bool isOwner)? onEventTap;

  const EventTypePage({
    super.key,
    required this.menuItem,
    required this.service,
    required this.translationPrefix,
    this.typeIcon = Icons.sports,
    this.onEventTap,
  });

  @override
  State<EventTypePage> createState() => _EventTypePageState();
}

class _EventTypePageState extends State<EventTypePage> {
  List<EventModel> _allEvents = [];
  Set<String> _myEventIds = {};
  bool _loading = true;
  String? _error;

  String get _prefix => widget.translationPrefix;

  List<EventModel> get _myEvents =>
      _allEvents.where((e) => _myEventIds.contains(e.id)).toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.service.getAll(),
        widget.service.getMyIds(),
      ]);
      if (mounted) {
        setState(() {
          _allEvents = results[0] as List<EventModel>;
          _myEventIds = results[1] as Set<String>;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = '$_prefix.error_load'.tr());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openCreate() async {
    await EventFormSheet.show(
      context: context,
      translationPrefix: _prefix,
      onSave: (data) async {
        final created = await widget.service.create(data);
        if (mounted) {
          setState(() {
            _allEvents.insert(0, created);
            _myEventIds.add(created.id);
          });
          _showSnack('$_prefix.success_created'.tr());
        }
      },
    );
    if (mounted) _silentReload();
  }

  Future<void> _silentReload() async {
    try {
      final results = await Future.wait([
        widget.service.getAll(),
        widget.service.getMyIds(),
      ]);
      if (mounted) {
        setState(() {
          _allEvents = results[0] as List<EventModel>;
          _myEventIds = results[1] as Set<String>;
        });
      }
    } catch (_) {}
  }

  Future<void> _openEdit(EventModel event) async {
    await EventFormSheet.show(
      context: context,
      translationPrefix: _prefix,
      event: event,
      onSave: (data) async {
        final updated = await widget.service.update(event.id, data);
        if (mounted) {
          setState(() {
            final idx = _allEvents.indexWhere((e) => e.id == event.id);
            if (idx != -1) _allEvents[idx] = updated;
          });
          _showSnack('$_prefix.success_updated'.tr());
        }
      },
    );
  }

  Future<void> _confirmDelete(EventModel event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F2A0F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$_prefix.delete_item'.tr(),
          style: const TextStyle(color: AppColors.white),
        ),
        content: Text(
          '$_prefix.confirm_delete'.tr(args: [event.name]),
          style: const TextStyle(color: AppColors.whiteSubtle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('$_prefix.cancel'.tr(),
                style: const TextStyle(color: AppColors.whiteSubtle)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('$_prefix.delete'.tr(),
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      await widget.service.delete(event.id);
      setState(() {
        _allEvents.removeWhere((e) => e.id == event.id);
        _myEventIds.remove(event.id);
      });
      _showSnack('$_prefix.success_deleted'.tr());
    } catch (_) {
      _showSnack('$_prefix.error_delete'.tr(), isError: true);
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
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.white),
              onPressed: _loading ? null : _load,
              tooltip: '$_prefix.retry'.tr(),
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
        body: _buildBody(),
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

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryLight),
      );
    }

    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _load);
    }

    return TabBarView(
      children: [
        _EventListView(
          events: _myEvents,
          myEventIds: _myEventIds,
          typeIcon: widget.typeIcon,
          onRefresh: _load,
          onEdit: _openEdit,
          onDelete: _confirmDelete,
          emptyTitle: '$_prefix.no_items_mine'.tr(),
          emptySubtitle: '$_prefix.no_items_mine_subtitle'.tr(),
          onAdd: _openCreate,
          onEventTap: widget.onEventTap,
        ),
        _EventListView(
          events: _allEvents,
          myEventIds: _myEventIds,
          typeIcon: widget.typeIcon,
          onRefresh: _load,
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
      return _EmptyView(
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
            onTap: onEventTap != null
                ? () => onEventTap!(event, isOwned)
                : null,
            onEdit: isOwned ? () => onEdit(event) : null,
            onDelete: isOwned ? () => onDelete(event) : null,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _EmptyView extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onAdd;

  const _EmptyView({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primaryLight.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: AppColors.primaryLight, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style:
                  const TextStyle(color: AppColors.whiteSubtle, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text('common.create'.tr()),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style:
                  const TextStyle(color: AppColors.whiteSubtle, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text('common.retry'.tr()),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryLight,
                side: const BorderSide(color: AppColors.primaryLight),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
