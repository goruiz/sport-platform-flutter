import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/events/leagues/data/datasource/courts_service.dart';
import 'package:sport_platform/modules/events/leagues/data/models/court_model.dart';
import 'package:sport_platform/modules/events/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/leagues/data/models/team_event_model.dart';

class MatchFormSheet extends StatefulWidget {
  final List<TeamEventModel> enrolledTeams;
  final String eventId;
  final MatchModel? match;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  const MatchFormSheet({
    super.key,
    required this.enrolledTeams,
    required this.eventId,
    this.match,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required List<TeamEventModel> enrolledTeams,
    required String eventId,
    MatchModel? match,
    required Future<void> Function(Map<String, dynamic>) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MatchFormSheet(
        enrolledTeams: enrolledTeams,
        eventId: eventId,
        match: match,
        onSave: onSave,
      ),
    );
  }

  @override
  State<MatchFormSheet> createState() => _MatchFormSheetState();
}

class _MatchFormSheetState extends State<MatchFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _courtsService = CourtsService();

  String? _homeTeamId;
  String? _awayTeamId;
  DateTime? _matchDate;
  final _matchDateCtrl = TextEditingController();
  String? _courtId;
  String _status = 'SCHEDULED';
  final _homeScoreCtrl = TextEditingController();
  final _awayScoreCtrl = TextEditingController();

  List<CourtModel> _courts = [];
  bool _loadingCourts = true;
  bool _saving = false;

  bool get _isEditing => widget.match != null;

  static const _statuses = [
    'SCHEDULED',
    'IN_PROGRESS',
    'FINISHED',
    'CANCELLED'
  ];

  @override
  void initState() {
    super.initState();
    final m = widget.match;
    if (m != null) {
      _homeTeamId = m.homeTeamId;
      _awayTeamId = m.awayTeamId;
      _matchDate = m.matchDate;
      _matchDateCtrl.text = _fmtDateTime(m.matchDate);
      _courtId = m.courtId;
      _status = m.status;
      _homeScoreCtrl.text = m.homeScore?.toString() ?? '';
      _awayScoreCtrl.text = m.awayScore?.toString() ?? '';
    }
    _loadCourts();
  }

  @override
  void dispose() {
    _matchDateCtrl.dispose();
    _homeScoreCtrl.dispose();
    _awayScoreCtrl.dispose();
    super.dispose();
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

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _matchDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _matchDate != null
          ? TimeOfDay.fromDateTime(_matchDate!)
          : TimeOfDay.now(),
    );
    if (time == null || !mounted) return;
    setState(() {
      _matchDate = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
      _matchDateCtrl.text = _fmtDateTime(_matchDate!);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        'homeTeamId': _homeTeamId,
        'awayTeamId': _awayTeamId,
        'matchDate': _apiDateTime(_matchDate!),
        'status': _status,
        'eventId': widget.eventId,
        if (_courtId != null) 'courtId': _courtId,
        if (_isEditing && _homeScoreCtrl.text.isNotEmpty)
          'homeScore': int.tryParse(_homeScoreCtrl.text),
        if (_isEditing && _awayScoreCtrl.text.isNotEmpty)
          'awayScore': int.tryParse(_awayScoreCtrl.text),
      };
      await widget.onSave(data);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F2A0F),
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.inputBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isEditing
                    ? 'leagues.edit_match'.tr()
                    : 'leagues.new_match'.tr(),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildTeamDropdown(
                label: 'leagues.home_team'.tr(),
                value: _homeTeamId,
                exclude: _awayTeamId,
                onChanged: (v) => setState(() => _homeTeamId = v),
              ),
              const SizedBox(height: 14),
              _buildTeamDropdown(
                label: 'leagues.away_team'.tr(),
                value: _awayTeamId,
                exclude: _homeTeamId,
                onChanged: (v) => setState(() => _awayTeamId = v),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _matchDateCtrl,
                readOnly: true,
                onTap: _pickDateTime,
                style: const TextStyle(color: AppColors.white),
                decoration: _decoration('leagues.match_date'.tr()).copyWith(
                  suffixIcon: const Icon(Icons.schedule,
                      color: AppColors.whiteSubtle, size: 18),
                ),
                validator: (_) => _matchDate == null
                    ? 'leagues.match_date'.tr()
                    : null,
              ),
              const SizedBox(height: 14),
              _buildCourtDropdown(),
              if (_isEditing) ...[
                const SizedBox(height: 14),
                _buildStatusDropdown(),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _homeScoreCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppColors.white),
                        decoration: _decoration(
                            '${'leagues.score'.tr()} (local)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _awayScoreCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppColors.white),
                        decoration: _decoration(
                            '${'leagues.score'.tr()} (visitante)'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _saving ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.inputBorder),
                        foregroundColor: AppColors.whiteSubtle,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('leagues.cancel'.tr()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.white),
                            )
                          : Text('leagues.save'.tr(),
                              style:
                                  const TextStyle(color: AppColors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamDropdown({
    required String label,
    required String? value,
    required String? exclude,
    required void Function(String?) onChanged,
  }) {
    final items = widget.enrolledTeams
        .where((t) => t.teamId != exclude)
        .map((t) => DropdownMenuItem(
              value: t.teamId,
              child: Text(t.teamName,
                  style: const TextStyle(color: AppColors.white)),
            ))
        .toList();

    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      dropdownColor: const Color(0xFF0F2A0F),
      style: const TextStyle(color: AppColors.white),
      decoration: _decoration(label),
      validator: (v) =>
          (v == null || v.isEmpty) ? label : null,
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
        child: Text(
          'leagues.no_courts'.tr(),
          style: const TextStyle(color: AppColors.whiteSubtle),
        ),
      ),
      ..._courts.map((c) => DropdownMenuItem(
            value: c.id,
            child: Text(c.displayName,
                style: const TextStyle(color: AppColors.white)),
          )),
    ];

    return DropdownButtonFormField<String?>(
      value: _courtId,
      items: items,
      onChanged: (v) => setState(() => _courtId = v),
      dropdownColor: const Color(0xFF0F2A0F),
      style: const TextStyle(color: AppColors.white),
      decoration: _decoration('leagues.court'.tr()),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _status,
      items: _statuses
          .map((s) => DropdownMenuItem(
                value: s,
                child: Text(_statusLabel(s),
                    style: const TextStyle(color: AppColors.white)),
              ))
          .toList(),
      onChanged: (v) => setState(() => _status = v ?? 'SCHEDULED'),
      dropdownColor: const Color(0xFF0F2A0F),
      style: const TextStyle(color: AppColors.white),
      decoration: _decoration('leagues.match_status_scheduled'.tr()),
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.whiteSubtle),
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryLight),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      );

  static String _statusLabel(String status) {
    const map = {
      'SCHEDULED': 'leagues.match_status_scheduled',
      'IN_PROGRESS': 'leagues.match_status_in_progress',
      'FINISHED': 'leagues.match_status_finished',
      'CANCELLED': 'leagues.match_status_cancelled',
    };
    return (map[status] ?? status).tr();
  }

  static String _fmtDateTime(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  static String _apiDateTime(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}'
      'T${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:00';
}
