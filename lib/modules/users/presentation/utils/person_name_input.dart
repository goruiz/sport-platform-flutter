import 'package:flutter/services.dart';
import 'package:sport_platform/modules/users/domain/name_rules.dart';

/// El teclado de un nombre o apellido: no deja escribir (ni pegar) números ni símbolos, solo lo que permite
/// `name_rules.dart`. Así el error ni siquiera llega a producirse.
final List<TextInputFormatter> personNameInputFormatters = [
  FilteringTextInputFormatter.allow(personNameTypableCharacter),
];
