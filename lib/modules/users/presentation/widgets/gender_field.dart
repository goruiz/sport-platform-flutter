import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/strings_constants/profile_strings_constants.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/users/domain/enums/gender.dart';

/// El género en un formulario: una ficha por opción y una sola elegida. Es obligatorio porque la categoría de un equipo
/// puede pedirlo.
///
/// La pantalla es dueña del valor ([value]); este campo solo lo dibuja y avisa ([onChanged]). Un valor que llega de fuera
/// (el de la cuenta, leído después de abrir el formulario) se ve porque la clave del campo cambia con él.
class GenderField extends StatelessWidget {
  final Gender? value;
  final ValueChanged<Gender> onChanged;

  /// Lo que el backend dijo de este campo (INVALID_GENDER), ya traducido; se muestra bajo las fichas hasta que se elija otro.
  final String? serverError;

  const GenderField({super.key, required this.value, required this.onChanged, this.serverError});

  @override
  Widget build(BuildContext context) {
    return FormField<Gender>(
      key: ValueKey('gender-${value?.apiValue}-$serverError'),
      initialValue: value,
      validator: (selected) => selected == null ? ProfileStringsConstants.required.tr() : null,
      builder: (state) {
        final error = state.errorText ?? serverError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                ProfileStringsConstants.gender.tr(),
                style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 13),
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final gender in Gender.values)
                  ChoiceChip(
                    label: Text(gender.translationKey.tr()),
                    selected: value == gender,
                    onSelected: (_) => onChanged(gender),
                  ),
              ],
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 6),
                child: Text(error, style: const TextStyle(color: AppColors.error, fontSize: 12.5)),
              ),
          ],
        );
      },
    );
  }
}
