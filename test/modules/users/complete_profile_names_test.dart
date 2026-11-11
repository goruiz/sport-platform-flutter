import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/users/domain/enums/gender.dart';
import 'package:sport_platform/modules/users/presentation/widgets/complete_profile_body.dart';

import '../../support/real_translations.dart';

class _Form {
  /// Por defecto el género y la fecha ya están dichos: estas pruebas son de los nombres, y esos dos son obligatorios.
  _Form({this.withoutPersonalData = false});

  final bool withoutPersonalData;
  Gender? get gender => withoutPersonalData ? null : Gender.female;
  DateTime? get birthDate => withoutPersonalData ? null : DateTime(2000, 1, 1);
  final formKey = GlobalKey<FormState>();
  final first = TextEditingController();
  final middle = TextEditingController();
  final last = TextEditingController();
  final secondLast = TextEditingController();
  final username = TextEditingController(text: 'usuario1');

  Widget build() => Scaffold(
        body: SingleChildScrollView(
          child: CompleteProfileBody(
            formKey: formKey,
            firstNameController: first,
            middleNameController: middle,
            lastNameController: last,
            secondLastNameController: secondLast,
            usernameController: username,
            isLoading: false,
            onSubmit: () {},
            gender: gender,
            onGenderChanged: (_) {},
            birthDate: birthDate,
            onBirthDateChanged: (_) {},
            editing: true,
          ),
        ),
      );
}

void main() {
  setUpAll(initRealTranslations);

  Future<void> typeInto(WidgetTester tester, int fieldIndex, String text) async {
    await tester.enterText(find.byType(TextFormField).at(fieldIndex), text);
    await tester.pump();
  }

  testWidgets('el teclado no deja escribir números ni símbolos en nombres y apellidos', (tester) async {
    final form = _Form();
    await pumpWithRealTranslations(tester, home: (_) => form.build());

    await typeInto(tester, 0, 'Juan123');
    await typeInto(tester, 1, 'José@#');
    await typeInto(tester, 2, 'Pérez_9');
    await typeInto(tester, 3, 'O\'Brien-4');

    expect(form.first.text, 'Juan');
    expect(form.middle.text, 'José');
    expect(form.last.text, 'Pérez');
    expect(form.secondLast.text, "O'Brien-");
  });

  testWidgets('un separador suelto pasa el teclado pero el formulario lo rechaza con su motivo', (tester) async {
    final form = _Form();
    await pumpWithRealTranslations(tester, home: (_) => form.build());

    await typeInto(tester, 0, 'Ana-');
    await typeInto(tester, 2, 'Pérez');

    expect(form.formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.textContaining('Solo letras'), findsOneWidget);
  });

  testWidgets('nombres bien escritos, con segundo nombre y segundo apellido vacíos, pasan', (tester) async {
    final form = _Form();
    await pumpWithRealTranslations(tester, home: (_) => form.build());

    await typeInto(tester, 0, 'María José');
    await typeInto(tester, 2, 'Núñez');

    expect(form.formKey.currentState!.validate(), isTrue);
  });

  testWidgets('el nombre y el apellido siguen siendo obligatorios', (tester) async {
    final form = _Form();
    await pumpWithRealTranslations(tester, home: (_) => form.build());

    expect(form.formKey.currentState!.validate(), isFalse);
  });

  testWidgets('el género y la fecha de nacimiento son obligatorios, porque la categoría de un equipo puede pedirlos', (tester) async {
    final form = _Form(withoutPersonalData: true);
    await pumpWithRealTranslations(tester, home: (_) => form.build());

    await typeInto(tester, 0, 'María José');
    await typeInto(tester, 2, 'Núñez');

    expect(form.formKey.currentState!.validate(), isFalse);
    await tester.pump();
    // Un «Requerido» por cada uno de los dos (los nombres ya están bien).
    expect(find.text('Requerido'), findsNWidgets(2));
  });

  testWidgets('con el género y la fecha dichos, el formulario muestra las dos opciones y la fecha', (tester) async {
    final form = _Form();
    await pumpWithRealTranslations(tester, home: (_) => form.build());

    expect(find.text('Masculino'), findsOneWidget);
    expect(find.text('Femenino'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNWidgets(2));
    expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Femenino')).selected, isTrue);
    expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Masculino')).selected, isFalse);
  });
}
