import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_input_decoration.dart';
import 'package:sport_platform/core/utils/date_formatters.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';

class LeagueInfoCard extends StatefulWidget {
  final EventModel event;
  final bool isOwner;
  final Future<void> Function(Map<String, dynamic>) onSave;
  final VoidCallback onError;

  const LeagueInfoCard({
    super.key,
    required this.event,
    required this.isOwner,
    required this.onSave,
    required this.onError,
  });

  @override
  State<LeagueInfoCard> createState() => _LeagueInfoCardState();
}

class _LeagueInfoCardState extends State<LeagueInfoCard> {
  bool _editing = false;
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _startDateCtrl;
  late final TextEditingController _endDateCtrl;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.event.name);
    _startDate = widget.event.startDate;
    _endDate = widget.event.endDate;
    _startDateCtrl =
        TextEditingController(text: DateFormatters.date(widget.event.startDate));
    _endDateCtrl =
        TextEditingController(text: DateFormatters.date(widget.event.endDate));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    super.dispose();
  }

  void _startEditing() => setState(() => _editing = true);

  void _cancelEditing() {
    setState(() {
      _editing = false;
      _nameCtrl.text = widget.event.name;
      _startDate = widget.event.startDate;
      _endDate = widget.event.endDate;
      _startDateCtrl.text = DateFormatters.date(widget.event.startDate);
      _endDateCtrl.text = DateFormatters.date(widget.event.endDate);
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? _startDate ?? DateTime.now());
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = date;
        _startDateCtrl.text = DateFormatters.date(date);
      } else {
        _endDate = date;
        _endDateCtrl.text = DateFormatters.date(date);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSave({
        'name': _nameCtrl.text.trim(),
        'startDate': DateFormatters.apiDate(_startDate!),
        'endDate': DateFormatters.apiDate(_endDate!),
      });
      if (mounted) setState(() => _editing = false);
    } catch (_) {
      if (mounted) widget.onError();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _editing ? AppColors.primaryLight : AppColors.inputBorder,
        ),
      ),
      child: _editing ? _buildEditMode() : _buildViewMode(),
    );
  }

  Widget _buildViewMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: widget.isOwner ? _startEditing : null,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.event.name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (widget.isOwner) ...[
                const SizedBox(width: 8),
                const Icon(Icons.edit_outlined,
                    color: AppColors.whiteSubtle, size: 16),
              ],
            ],
          ),
        ),
        if (widget.event.description != null &&
            widget.event.description!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            widget.event.description!,
            style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 14),
          ),
        ],
        const SizedBox(height: 16),
        GestureDetector(
          onTap: widget.isOwner ? _startEditing : null,
          behavior: HitTestBehavior.opaque,
          child: _InfoRow(
            icon: Icons.calendar_today,
            label:
                '${DateFormatters.date(widget.event.startDate)} - ${DateFormatters.date(widget.event.endDate)}',
          ),
        ),
        if (widget.event.format.isNotEmpty) ...[
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.format_list_bulleted, label: widget.event.format),
        ],
        if (widget.event.eventTypeName != null &&
            widget.event.eventTypeName!.isNotEmpty) ...[
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.military_tech, label: widget.event.eventTypeName!),
        ],
        const SizedBox(height: 8),
        _InfoRow(
          icon: Icons.access_time,
          label: DateFormatters.date(widget.event.createdAt),
        ),
      ],
    );
  }

  Widget _buildEditMode() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameCtrl,
            autofocus: true,
            style: const TextStyle(color: AppColors.white),
            decoration: AppInputDecoration.standard('leagues.name'.tr()),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'leagues.name_required'.tr()
                : null,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _startDateCtrl,
                  readOnly: true,
                  onTap: () => _pickDate(isStart: true),
                  style: const TextStyle(color: AppColors.white),
                  decoration:
                      AppInputDecoration.standard('leagues.start_date'.tr())
                          .copyWith(
                    suffixIcon: const Icon(Icons.calendar_today,
                        color: AppColors.whiteSubtle, size: 18),
                  ),
                  validator: (_) => _startDate == null
                      ? 'leagues.start_date_required'.tr()
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _endDateCtrl,
                  readOnly: true,
                  onTap: () => _pickDate(isStart: false),
                  style: const TextStyle(color: AppColors.white),
                  decoration:
                      AppInputDecoration.standard('leagues.end_date'.tr())
                          .copyWith(
                    suffixIcon: const Icon(Icons.calendar_today,
                        color: AppColors.whiteSubtle, size: 18),
                  ),
                  validator: (_) {
                    if (_endDate == null) {
                      return 'leagues.end_date_required'.tr();
                    }
                    if (_startDate != null && _endDate!.isBefore(_startDate!)) {
                      return 'leagues.date_order_error'.tr();
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          if (widget.event.format.isNotEmpty) ...[
            const SizedBox(height: 16),
            _InfoRow(
                icon: Icons.format_list_bulleted, label: widget.event.format),
          ],
          if (widget.event.eventTypeName != null &&
              widget.event.eventTypeName!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(
                icon: Icons.military_tech, label: widget.event.eventTypeName!),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : _cancelEditing,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.inputBorder),
                    foregroundColor: AppColors.whiteSubtle,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('leagues.cancel'.tr()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
                          style: const TextStyle(color: AppColors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.whiteSubtle, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
