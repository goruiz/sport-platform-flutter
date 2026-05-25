import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/leagues/data/models/league_model.dart';
import 'package:sport_platform/modules/leagues/data/datasource/league_service.dart';
import 'package:sport_platform/modules/leagues/presentation/widgets/league_card.dart';
import 'package:sport_platform/modules/leagues/presentation/widgets/league_form_sheet.dart';

class LeaguesPage extends StatefulWidget {
  final MenuItemModel item;

  const LeaguesPage({super.key, required this.item});

  @override
  State<LeaguesPage> createState() => _LeaguesPageState();
}

class _LeaguesPageState extends State<LeaguesPage> {
  final _service = LeagueService();
  List<LeagueModel> _leagues = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLeagues();
  }

  Future<void> _loadLeagues() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final leagues = await _service.getAll();
      if (mounted) setState(() => _leagues = leagues);
    } catch (e) {
      if (mounted) setState(() => _error = 'leagues.error_load'.tr());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openCreateSheet() async {
    await LeagueFormSheet.show(
      context: context,
      onSave: (data) async {
        final created = await _service.create(data);
        if (mounted) {
          setState(() => _leagues.insert(0, created));
          _showSnack('leagues.success_created'.tr());
        }
      },
    );
  }

  Future<void> _openEditSheet(LeagueModel league) async {
    await LeagueFormSheet.show(
      context: context,
      league: league,
      onSave: (data) async {
        final updated = await _service.update(league.id, data);
        if (mounted) {
          setState(() {
            final idx = _leagues.indexWhere((l) => l.id == league.id);
            if (idx != -1) _leagues[idx] = updated;
          });
          _showSnack('leagues.success_updated'.tr());
        }
      },
    );
  }

  Future<void> _confirmDelete(LeagueModel league) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F2A0F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'leagues.delete_league'.tr(),
          style: const TextStyle(color: AppColors.white),
        ),
        content: Text(
          'leagues.confirm_delete'.tr(args: [league.name]),
          style: const TextStyle(color: AppColors.whiteSubtle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'leagues.cancel'.tr(),
              style: const TextStyle(color: AppColors.whiteSubtle),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'leagues.delete'.tr(),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      await _service.delete(league.id);
      setState(() => _leagues.removeWhere((l) => l.id == league.id));
      _showSnack('leagues.success_deleted'.tr());
    } catch (_) {
      _showSnack('leagues.error_delete'.tr(), isError: true);
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
    return Scaffold(
      backgroundColor: AppColors.backgroundEnd,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: Text(
          widget.item.displayName.tr(),
          style: const TextStyle(color: AppColors.white),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.white),
            onPressed: _loading ? null : _loadLeagues,
            tooltip: 'leagues.retry'.tr(),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateSheet,
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.white,
        tooltip: 'leagues.new_league'.tr(),
        child: const Icon(Icons.add),
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
      return _ErrorView(message: _error!, onRetry: _loadLeagues);
    }

    if (_leagues.isEmpty) {
      return _EmptyView(onAdd: _openCreateSheet);
    }

    return RefreshIndicator(
      onRefresh: _loadLeagues,
      color: AppColors.primaryLight,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 100),
        itemCount: _leagues.length,
        itemBuilder: (_, i) => LeagueCard(
          league: _leagues[i],
          onEdit: () => _openEditSheet(_leagues[i]),
          onDelete: () => _confirmDelete(_leagues[i]),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyView({required this.onAdd});

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
              child: const Icon(Icons.military_tech,
                  color: AppColors.primaryLight, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'leagues.no_leagues'.tr(),
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'leagues.no_leagues_subtitle'.tr(),
              style:
                  const TextStyle(color: AppColors.whiteSubtle, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text('leagues.new_league'.tr()),
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
              label: Text('leagues.retry'.tr()),
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
