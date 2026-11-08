import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/core/network/authorized_image.dart';

void main() {
  const apiBaseUrl = 'http://localhost:8080/api';

  group('resolveNetworkImage', () {
    test('una dirección relativa es del API: se completa y lleva el token de la sesión', () {
      final image = resolveNetworkImage(
        'players/p1/photo?v=123',
        apiBaseUrl: apiBaseUrl,
        token: 'abc',
      );

      expect(image.url, 'http://localhost:8080/api/players/p1/photo?v=123');
      expect(image.headers, {'Authorization': 'Bearer abc'});
    });

    test('con o sin barra inicial da la misma dirección', () {
      final withSlash = resolveNetworkImage('/players/p1/photo', apiBaseUrl: apiBaseUrl, token: 't');
      final without = resolveNetworkImage('players/p1/photo', apiBaseUrl: apiBaseUrl, token: 't');

      expect(withSlash.url, without.url);
    });

    test('una base que termina en barra no duplica la barra', () {
      final image = resolveNetworkImage('players/p1/photo', apiBaseUrl: '$apiBaseUrl/', token: 't');

      expect(image.url, 'http://localhost:8080/api/players/p1/photo');
    });

    test('una dirección completa del propio API también lleva el token', () {
      final image = resolveNetworkImage(
        'http://localhost:8080/api/players/p1/photo',
        apiBaseUrl: apiBaseUrl,
        token: 'abc',
      );

      expect(image.headers, isNotEmpty);
    });

    test('el logo de otro sitio se pide tal cual y nunca lleva el token', () {
      final image = resolveNetworkImage(
        'https://cdn.example.com/logo.png',
        apiBaseUrl: apiBaseUrl,
        token: 'abc',
      );

      expect(image.url, 'https://cdn.example.com/logo.png');
      expect(image.headers, isEmpty);
    });

    test('un sitio que solo se parece al API no recibe el token', () {
      final image = resolveNetworkImage(
        'http://localhost:8080/api-falsa/foto.png',
        apiBaseUrl: apiBaseUrl,
        token: 'abc',
      );

      expect(image.headers, isEmpty);
    });

    test('sin sesión no hay cabecera de autorización', () {
      expect(resolveNetworkImage('players/p1/photo', apiBaseUrl: apiBaseUrl).headers, isEmpty);
      expect(resolveNetworkImage('players/p1/photo', apiBaseUrl: apiBaseUrl, token: '').headers, isEmpty);
    });
  });
}
