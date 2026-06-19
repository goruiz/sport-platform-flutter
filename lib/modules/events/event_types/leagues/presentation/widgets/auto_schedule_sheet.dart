import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_input_decoration.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/courts_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/domain/repositories/i_league_schedule_repository.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/court_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/event_schedule_config_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/shared/widgets/sheet_handle.dart';

class AutoScheduleSheet extends StatefulWidget {
  final String eventId;
  final Future<void> Function(List<MatchModel> generated) onGenerated;

  const AutoScheduleSheet({
    super.key,
    required this.eventId,
    required this.onGenerated,
  });

  static Future<void> show({
    required BuildContext context,
    required String eventId,
    required Future<void> Function(List<MatchModel>) onGenerated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AutoScheduleSheet(
        eventId: eventId,
        onGenerated: onGenerated,
      ),
    );
  }

  @override
  State<AutoScheduleSheet> createState() => _AutoScheduleSheetState();
}

class _AutoScheduleSheetState extends State<AutoScheduleSheet> {
  static const _allDays = [
    'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'
  ];

  final _formKey = GlobalKey<FormState>();
  late final ILeagueScheduleRepository _scheduleRepo;
  late final CourtsService _courtsService;

  final Set<String> _selectedDays = {};
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  final _durationCtrl = TextEditingController(text: '90');
  final _halvesBreakCtrl = TextEditingController(text: '15');
  final _matchBreakCtrl = TextEditingController(text: '30');
  String? _courtId;
  final List<DateTime> _blockedDates = [];

  List<CourtModel> _courts = [];
  bool _loadingCourts = true;
  bool _loadingConfig = true;
  bool _saving = false;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _scheduleRepo = getIt<ILeagueScheduleRepository>();
    _courtsService = getIt<CourtsService>();
    _loadData();
  }

  @override
  void dispose() {
    _durationCtrl.dispose();
    _halvesBreakCtrl.dispose();
    _matchBreakCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadCourts(), _loadConfig()]);
  }

  Future<void> _loadCourts() async {
    try {
      final courts = await _courtsService.getAll();
      if (mounted) setState(() => _courts = courts);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingCourts = false);
    }
  }

  Future<void> _loadConfig() async {
    try {
      final config = await _scheduleRepo.getConfig(widget.eventId);
      if (config != null && mounted) _applyConfig(config);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingConfig = false);
    }
  }

  void _applyConfig(EventScheduleConfigModel config) {
    setState(() {
      _selectedDays
        ..clear()
        ..addAll(config.playDays);
      final parts = config.startTime.split(':');
      _startTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      );
      _durationCtrl.text = config.matchDurationMinutes.toString();
      _halvesBreakCtrl.text = config.breakBetweenHalvesMinutes.toString();
      _matchBreakCtrl.text = config.breakBetweenMatchesMinutes.toString();
      _courtId = config.courtId;
      _blockedDates
        ..clear()
        ..addAll(config.blockedDates.map(DateTime.parse));
    });
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null && mounted) setState(() => _startTime = picked);
  }

  Future<void> _addBlockedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'leagues.schedule_pick_blocked_date'.tr(),
    );
    if (picked == null || !mounted) return;
    final alreadyAdded = _blockedDates.any(
      (d) => d.year == picked.year && d.month == picked.month && d.day == picked.day,
    );
    if (!alreadyAdded) {
      setState(() {
        _blockedDates.add(picked);
        _blockedDates.sort();
      });
    }
  }

  void _removeBlockedDate(DateTime date) {
    setState(() => _blockedDates.removeWhere(
          (d) => d.year == date.year && d.month == date.month && d.day == date.day,
        ));
  }

  String get _startTimeLabel =>
      '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';

  static String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> _buildPayload() => {
        'playDays': _selectedDays.toList(),
        'startTime': _startTimeLabel,
        'matchDurationMinutes': int.tryParse(_durationCtrl.text) ?? 90,
        'breakBetweenHalvesMinutes': int.tryParse(_halvesBreakCtrl.text) ?? 15,
        'breakBetweenMatchesMinutes': int.tryParse(_matchBreakCtrl.text) ?? 30,
        if (_courtId != null) 'courtId': _courtId,
        'blockedDates': _blockedDates.map(_isoDate).toList(),
      };

  Future<void> _saveConfig() async {
    if (!_validate()) return;
    setState(() => _saving = true);
    try {
      await _scheduleRepo.saveConfig(widget.eventId, _buildPayload());
      if (mounted) _showSnack('leagues.schedule_config_saved'.tr());
    } catch (_) {
      if (mounted) _showSnack('leagues.schedule_error_save'.tr(), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _generate() async {
    if (!_validate()) return;
    setState(() => _generating = true);
    try {
      await _scheduleRepo.saveConfig(widget.eventId, _buildPayload());
      final (matches, warning) = await _scheduleRepo.generate(widget.eventId);
      await widget.onGenerated(matches);
      if (mounted) {
        if (warning != null) {
          _showSnack(warning, isWarning: true);
        }
        _showSnack('leagues.schedule_generated'.tr(
          namedArgs: {'count': matches.length.toString()},
        ));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        bool isCapacityError = false;
        if (e is DioException) {
          final data = e.response?.data;
          final msg = data is Map ? (data['message'] as String? ?? '') : '';
          isCapacityError = msg.contains('date range') || msg.contains('play days');
        }
        _showSnack(
          isCapacityError
              ? 'leagues.schedule_no_space'.tr()
              : 'leagues.schedule_error_generate'.tr(),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  bool _validate() {
    if (_selectedDays.isEmpty) {
      _showSnack('leagues.schedule_days_required'.tr(), isError: true);
      return false;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return false;
    return true;
  }

  void _showSnack(String message, {bool isError = false, bool isWarning = false}) {
    Color bg = AppColors.success;
    if (isError) bg = AppColors.error;
    if (isWarning) bg = const Color(0xFFFFB347);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        duration: isWarning
            ? const Duration(seconds: 6)
            : const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.sheetBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              const SizedBox(height: 20),
              Text(
                'leagues.auto_schedule_title'.tr(),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'leagues.auto_schedule_subtitle'.tr(),
                style: const TextStyle(
                    color: AppColors.whiteSubtle, fontSize: 13),
              ),
              const SizedBox(height: 20),
              if (_loadingConfig)
                const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primaryLight),
                )
              else ...[
                _sectionLabel('leagues.schedule_play_days'.tr()),
                const SizedBox(height: 8),
                _buildDayChips(),
                const SizedBox(height: 16),
                _sectionLabel('leagues.schedule_start_time'.tr()),
                const SizedBox(height: 8),
                _buildTimePicker(),
                const SizedBox(height: 16),
                _sectionLabel('leagues.schedule_durations'.tr()),
                const SizedBox(height: 8),
                _buildMinutesField(
                  controller: _durationCtrl,
                  label: 'leagues.schedule_match_duration'.tr(),
                ),
                const SizedBox(height: 12),
                _buildMinutesField(
                  controller: _halvesBreakCtrl,
                  label: 'leagues.schedule_halves_break'.tr(),
                ),
                const SizedBox(height: 12),
                _buildMinutesField(
                  controller: _matchBreakCtrl,
                  label: 'leagues.schedule_match_break'.tr(),
                ),
                const SizedBox(height: 16),
                _sectionLabel('leagues.court'.tr()),
                const SizedBox(height: 8),
                _buildCourtDropdown(),
                const SizedBox(height: 16),
                _sectionLabel('leagues.schedule_blocked_dates'.tr()),
                const SizedBox(height: 8),
                _buildBlockedDates(),
                const SizedBox(height: 28),
                _buildActions(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: AppColors.whiteSubtle,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      );

  Widget _buildDayChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: _allDays.map((day) {
        final selected = _selectedDays.contains(day);
        return FilterChip(
          label: Text(
            'leagues.day_${day.toLowerCase()}'.tr(),
            style: TextStyle(
              color: selected ? AppColors.primaryDark : AppColors.whiteSubtle,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          selected: selected,
          onSelected: (v) => setState(() {
            if (v) {
              _selectedDays.add(day);
            } else {
              _selectedDays.remove(day);
            }
          }),
          selectedColor: AppColors.primaryLight,
          backgroundColor: AppColors.inputFill,
          checkmarkColor: AppColors.primaryDark,
          side: BorderSide(
            color: selected ? AppColors.primaryLight : AppColors.inputBorder,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        );
      }).toList(),
    );
  }

  Widget _buildTimePicker() {
    return GestureDetector(
      onTap: _pickStartTime,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time,
                color: AppColors.whiteSubtle, size: 18),
            const SizedBox(width: 12),
            Text(
              _startTimeLabel,
              style: const TextStyle(color: AppColors.white, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinutesField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: AppColors.white),
      decoration: AppInputDecoration.standard(label).copyWith(
        suffixText: 'min',
        suffixStyle:
            const TextStyle(color: AppColors.whiteSubtle, fontSize: 13),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return label;
        final n = int.tryParse(v);
        if (n == null || n < 0) return 'leagues.schedule_invalid_minutes'.tr();
        return null;
      },
    );
  }

  Widget _buildCourtDropdown() {
    if (_loadingCourts) {
      return const SizedBox(
        height: 56,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primaryLight),
          ),
        ),
      );
    }
    final items = <DropdownMenuItem<String?>>[
      DropdownMenuItem(
        value: null,
        child: Text('leagues.no_courts'.tr(),
            style: const TextStyle(color: AppColors.whiteSubtle)),
      ),
      ..._courts.map((c) => DropdownMenuItem(
            value: c.id,
            child: Text(c.displayName,
                style: const TextStyle(color: AppColors.white)),
          )),
    ];
    return DropdownButtonFormField<String?>(
      // ignore: deprecated_member_use
      value: _courtId,
      items: items,
      onChanged: (v) => setState(() => _courtId = v),
      dropdownColor: AppColors.sheetBackground,
      style: const TextStyle(color: AppColors.white),
      decoration: AppInputDecoration.standard('leagues.court'.tr()),
    );
  }

  Widget _buildBlockedDates() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_blockedDates.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _blockedDates.map((d) {
              final label = _isoDate(d);
              return Chip(
                label: Text(label,
                    style: const TextStyle(
                        color: AppColors.white, fontSize: 12)),
                deleteIcon: const Icon(Icons.close,
                    size: 14, color: AppColors.whiteSubtle),
                onDeleted: () => _removeBlockedDate(d),
                backgroundColor: AppColors.inputFill,
                side: const BorderSide(color: AppColors.inputBorder),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: _addBlockedDate,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.inputBorder),
            foregroundColor: AppColors.whiteSubtle,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.block, size: 16),
          label: Text('leagues.schedule_add_blocked_date'.tr(),
              style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildActions() {
    final busy = _saving || _generating;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton(
          onPressed: busy ? null : _saveConfig,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.primaryLight),
            foregroundColor: AppColors.primaryLight,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primaryLight),
                )
              : Text('leagues.schedule_save_config'.tr()),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: busy ? null : _generate,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: _generating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.white),
                )
              : const Icon(Icons.auto_awesome, color: AppColors.white, size: 18),
          label: Text(
            'leagues.schedule_generate'.tr(),
            style: const TextStyle(color: AppColors.white),
          ),
        ),
      ],
    );
  }
}
