import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/strings_constants/profile_strings_constants.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/utils/date_formatters.dart';
import 'package:sport_platform/modules/users/domain/birth_date_rules.dart';

/// La fecha de nacimiento en un formulario: un campo que abre el selector de fechas. Es obligatoria porque la categoría de
/// un equipo puede pedir una edad.
///
/// El selector no ofrece lo que el backend rechazaría (el futuro, ni a alguien de más años de los que puede tener una
/// persona: ver `birth_date_rules.dart`) y abre en una fecha razonable en vez de en hoy.
///
/// La pantalla es dueña del valor ([value]); este campo solo lo dibuja y avisa ([onChanged]). Un valor que llega de fuera
/// (el de la cuenta, leído después de abrir el formulario) se ve porque la clave del campo cambia con él.
class BirthDateField extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  /// Lo que el backend dijo de este campo (INVALID_BIRTH_DATE), ya traducido; se muestra hasta que se elija otra fecha.
  final String? serverError;

  /// El día de hoy. Solo se pasa en las pruebas.
  final DateTime? today;

  const BirthDateField({super.key, required this.value, required this.onChanged, this.serverError, this.today});

  DateTime get _today => dateOnly(today ?? DateTime.now());

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      key: ValueKey('birth-date-${value?.toIso8601String()}-$serverError'),
      initialValue: value,
      validator: _validate,
      builder: (state) {
        final error = state.errorText ?? serverError;
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _pick(context),
          child: InputDecorator(
            isEmpty: value == null,
            decoration: InputDecoration(
              hintText: ProfileStringsConstants.birthDate.tr(),
              prefixIcon: const Icon(Icons.cake_outlined, size: 20),
              suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
              errorText: error,
              errorMaxLines: 3,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            child: Text(
              value == null ? '' : DateFormatters.date(value!),
              style: const TextStyle(color: AppColors.white, fontSize: 15),
            ),
          ),
        );
      },
    );
  }

  String? _validate(DateTime? selected) {
    final issue = checkBirthDate(selected, today: _today);
    if (issue == null) return null;
    return issue.translationKey?.tr() ?? ProfileStringsConstants.required.tr();
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? initialBirthDateForPicker(_today),
      firstDate: oldestBirthDate(_today),
      lastDate: _today,
      helpText: ProfileStringsConstants.birthDate.tr(),
    );
    if (picked != null) onChanged(dateOnly(picked));
  }
}
