import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/modules/users/presentation/widgets/complete_profile_body.dart';

import '../../support/real_translations.dart';

class _Form {
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
}
