import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_input_decoration.dart';
import 'package:sport_platform/core/utils/date_formatters.dart';
import 'package:sport_platform/modules/events/shared/data/models/event_model.dart';
import 'package:sport_platform/shared/widgets/sheet_handle.dart';

class EventFormSheet extends StatefulWidget {
  final EventModel? event;
  final String translationPrefix;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  const EventFormSheet({
    super.key,
    this.event,
    required this.translationPrefix,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required String translationPrefix,
    EventModel? event,
    required Future<void> Function(Map<String, dynamic>) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EventFormSheet(
        event: event,
        translationPrefix: translationPrefix,
        onSave: onSave,
      ),
    );
  }

  @override
  State<EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends State<EventFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _startDateCtrl;
  late final TextEditingController _endDateCtrl;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _saving = false;

  String get _prefix => widget.translationPrefix;
  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _startDate = e?.startDate;
    _endDate = e?.endDate;
    _startDateCtrl = TextEditingController(
        text: e != null ? DateFormatters.date(e.startDate) : '');
    _endDateCtrl = TextEditingController(
        text: e != null ? DateFormatters.date(e.endDate) : '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    super.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSave({
        'name': _nameCtrl.text.trim(),
        'startDate': DateFormatters.apiDate(_startDate!),
        'endDate': DateFormatters.apiDate(_endDate!),
      });
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      // El form permanece abierto para que el usuario reintente
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
                _isEditing ? '$_prefix.edit_item'.tr() : '$_prefix.new_item'.tr(),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: AppColors.white),
                decoration: AppInputDecoration.standard('$_prefix.name'.tr()),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? '$_prefix.name_required'.tr()
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
                      decoration: AppInputDecoration.standard('$_prefix.start_date'.tr())
                          .copyWith(
                        suffixIcon: const Icon(Icons.calendar_today,
                            color: AppColors.whiteSubtle, size: 18),
                      ),
                      validator: (_) => _startDate == null
                          ? '$_prefix.start_date_required'.tr()
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
                      decoration: AppInputDecoration.standard('$_prefix.end_date'.tr())
                          .copyWith(
                        suffixIcon: const Icon(Icons.calendar_today,
                            color: AppColors.whiteSubtle, size: 18),
                      ),
                      validator: (_) {
                        if (_endDate == null) {
                          return '$_prefix.end_date_required'.tr();
                        }
                        if (_startDate != null &&
                            _endDate!.isBefore(_startDate!)) {
                          return '$_prefix.date_order_error'.tr();
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.inputBorder),
              foregroundColor: AppColors.whiteSubtle,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('$_prefix.cancel'.tr()),
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
                : Text('$_prefix.save'.tr(),
                    style: const TextStyle(color: AppColors.white)),
          ),
        ),
      ],
    );
  }
}
