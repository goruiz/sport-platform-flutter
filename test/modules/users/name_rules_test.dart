import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/users/domain/name_rules.dart';
import 'package:sport_platform/modules/users/presentation/utils/person_name_input.dart';

void main() {
  group('checkPersonName: lo que sí sirve', () {
    test('nombres con letras, tildes, ñ y diéresis', () {
      for (final name in ['Juan', 'María', 'Núñez', 'Muñoz', 'Müller', 'Zoë', 'ÁNGEL', 'François']) {
        expect(checkPersonName(name, required: true), isNull, reason: name);
      }
    });

    test('nombres compuestos con espacio, guion o apóstrofo', () {
      for (final name in ['María José', 'Ana-María', "O'Brien", 'D’Angelo', 'De la Cruz', 'Jean-Luc Picard']) {
        expect(checkPersonName(name, required: true), isNull, reason: name);
      }
    });

    test('espacios de sobra en los extremos o entre palabras no invalidan: se normalizan', () {
      expect(checkPersonName('  Juan  Carlos  ', required: true), isNull);
    });

    test('un nombre con la tilde escrita como marca aparte (decomposed) también sirve', () {
      expect(checkPersonName('José', required: true), isNull);
    });

    test('un alfabeto que no es el latino también son letras', () {
      expect(checkPersonName('Дмитрий', required: true), isNull);
    });
  });

  group('checkPersonName: lo que no sirve', () {
    test('números', () {
      for (final name in ['Juan1', '1Juan', 'Ju4n', '123', 'Ana 2']) {
        expect(checkPersonName(name, required: true), PersonNameIssue.invalidCharacters, reason: name);
      }
    });

    test('símbolos', () {
      for (final name in ['Juan@', 'Ana_María', 'Pedro#', r'Luis$', 'Sofía!', 'Carlos.', 'a/b', 'Juan;', '<b>Juan</b>', 'Ana😀']) {
        expect(checkPersonName(name, required: true), PersonNameIssue.invalidCharacters, reason: name);
      }
    });

    test('un separador suelto, doble o en un extremo no es un nombre', () {
      for (final name in ['-', "'", 'Juan-', '-Juan', "'Juan", 'Ana--María', "Ana'-María", 'Ana -María']) {
        expect(checkPersonName(name, required: true), PersonNameIssue.invalidCharacters, reason: name);
      }
    });
  });

  group('checkPersonName: obligatorio u opcional', () {
    test('un campo obligatorio vacío, en blanco o nulo pide un valor', () {
      expect(checkPersonName('', required: true), PersonNameIssue.empty);
      expect(checkPersonName('   ', required: true), PersonNameIssue.empty);
      expect(checkPersonName(null, required: true), PersonNameIssue.empty);
    });

    test('un campo opcional vacío sirve, pero si se llena tiene que ser válido', () {
      expect(checkPersonName('', required: false), isNull);
      expect(checkPersonName('  ', required: false), isNull);
      expect(checkPersonName('Jose3', required: false), PersonNameIssue.invalidCharacters);
      expect(checkPersonName('José', required: false), isNull);
    });
  });

  test('normalizePersonName quita los extremos y deja un solo espacio entre palabras', () {
    expect(normalizePersonName('  Juan   Carlos '), 'Juan Carlos');
    expect(normalizePersonName('Ana-María'), 'Ana-María');
  });

  test('cada motivo tiene su texto: «vacío» lo dice cada pantalla y «inválido» tiene clave', () {
    expect(PersonNameIssue.empty.translationKey, isNull);
    expect(PersonNameIssue.invalidCharacters.translationKey, 'profile.name_invalid');
  });

  group('el teclado de un nombre (personNameInputFormatters)', () {
    TextEditingValue type(String text) {
      var value = TextEditingValue.empty;
      for (final formatter in personNameInputFormatters) {
        value = formatter.formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length)),
        );
      }
      return value;
    }

    test('no deja escribir ni pegar números ni símbolos', () {
      expect(type('Juan123').text, 'Juan');
      expect(type('Ana@#_María').text, 'AnaMaría');
      expect(type('Pedro!?').text, 'Pedro');
      expect(type('12345').text, '');
    });

    test('deja pasar letras con tilde, espacios, guiones y apóstrofos', () {
      expect(type("María-José O'Brien Núñez").text, "María-José O'Brien Núñez");
    });
  });
}
