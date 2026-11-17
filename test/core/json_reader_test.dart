import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/core/network/json_reader.dart';

void main() {
  JsonReader readerOf(Map<String, dynamic> json) => JsonReader(json, resource: 'partido');

  group('lo obligatorio', () {
    test('un campo que está se lee con su tipo', () {
      final reader = readerOf({'id': 7, 'name': 'Final', 'goals': 3.0, 'date': '2026-11-11T10:30:00'});

      expect(reader.requiredString('id'), '7');
      expect(reader.requiredString('name'), 'Final');
      expect(reader.requiredInt('goals'), 3);
      expect(reader.requiredDateTime('date'), DateTime(2026, 11, 11, 10, 30));
    });

    test('si falta no se inventa nada: es un error que dice el recurso y el campo', () {
      final reader = readerOf({});

      expect(
        () => reader.requiredString('id'),
        throwsA(isA<MalformedResponseException>()
            .having((e) => e.resource, 'resource', 'partido')
            .having((e) => e.field, 'field', 'id')
            .having((e) => e.toString(), 'texto', contains('partido.id falta'))),
      );
      expect(() => reader.requiredDateTime('matchDate'), throwsA(isA<MalformedResponseException>()));
      expect(() => reader.requiredInt('points'), throwsA(isA<MalformedResponseException>()));
    });

    test('una fecha o un número con otro formato también es un error, no un valor por defecto', () {
      final reader = readerOf({'matchDate': 'mañana', 'points': 'muchos'});

      expect(() => reader.requiredDateTime('matchDate'), throwsA(isA<MalformedResponseException>()));
      expect(() => reader.requiredInt('points'), throwsA(isA<MalformedResponseException>()));
    });
  });

  group('lo opcional', () {
    test('si falta es null, y si está se lee', () {
      final reader = readerOf({'endsAt': '2026-11-11T12:00:00', 'latitude': 10, 'location': 'Cancha 1'});

      expect(reader.optionalDateTime('endsAt'), DateTime(2026, 11, 11, 12));
      expect(reader.optionalDateTime('missing'), isNull);
      expect(reader.optionalInt('missing'), isNull);
      expect(reader.optionalString('missing'), isNull);
      expect(reader.optionalDouble('latitude'), 10.0);
      expect(reader.optionalDouble('missing'), isNull);
      expect(reader.optionalString('location'), 'Cancha 1');
    });

    test('un valor presente pero roto sí es un error', () {
      expect(() => readerOf({'endsAt': 'pronto'}).optionalDateTime('endsAt'), throwsA(isA<MalformedResponseException>()));
      expect(() => readerOf({'latitude': 'norte'}).optionalDouble('latitude'), throwsA(isA<MalformedResponseException>()));
    });
  });

  group('textos, marcadores, listas y objetos', () {
    test('textOrEmpty deja en blanco el texto que falta y flag solo es verdadero con true', () {
      final reader = readerOf({'description': 'Liga', 'isCaptain': true, 'isPublic': 'true'});

      expect(reader.textOrEmpty('description'), 'Liga');
      expect(reader.textOrEmpty('missing'), '');
      expect(reader.flag('isCaptain'), isTrue);
      expect(reader.flag('isPublic'), isFalse);
      expect(reader.flag('missing'), isFalse);
    });

    test('una lista que falta es vacía y lo que parse no entiende se descarta', () {
      final reader = readerOf({
        'phases': [
          {'code': 'A'},
          {'code': 'desconocida'},
          'basura',
        ],
      });

      final codes = reader.list<String>('phases', (json) => json['code'] == 'A' ? 'ok' : null);

      expect(codes, ['ok']);
      expect(reader.list<String>('missing', (_) => 'x'), isEmpty);
      expect(() => readerOf({'phases': 'no es lista'}).list<String>('phases', (_) => 'x'), throwsA(isA<MalformedResponseException>()));
    });

    test('un objeto anidado se lee con su propio nombre de recurso', () {
      final reader = readerOf({'format': {'name': 'Liga'}});

      final nested = reader.optionalObject('format')!;

      expect(nested.requiredString('name'), 'Liga');
      expect(() => nested.requiredString('structure'), throwsA(isA<MalformedResponseException>().having((e) => e.resource, 'resource', 'partido.format')));
      expect(reader.optionalObject('missing'), isNull);
    });
  });
}
