import 'package:flutter_test/flutter_test.dart';
import 'package:sport_platform/core/utils/external_links.dart';

void main() {
  group('ExternalLinks.calendarEvent', () {
    test('arma la plantilla de Google Calendar con las horas locales sin zona', () {
      final uri = ExternalLinks.calendarEvent(
        title: 'Tigres vs Leones',
        start: DateTime(2026, 11, 5, 18, 30),
        end: DateTime(2026, 11, 5, 19, 45),
        location: 'Cancha 1',
        details: 'Liga de barrio',
      );

      expect(uri.host, 'calendar.google.com');
      expect(uri.path, '/calendar/render');
      expect(uri.queryParameters, {
        'action': 'TEMPLATE',
        'text': 'Tigres vs Leones',
        'dates': '20261105T183000/20261105T194500',
        'location': 'Cancha 1',
        'details': 'Liga de barrio',
      });
    });

    test('rellena con ceros los meses, días y horas de una cifra', () {
      final uri = ExternalLinks.calendarEvent(
        title: 'x',
        start: DateTime(2026, 1, 2, 3, 4),
        end: DateTime(2026, 1, 2, 5, 6),
      );

      expect(uri.queryParameters['dates'], '20260102T030400/20260102T050600');
    });

    test('omite el lugar y el detalle cuando no hay', () {
      final uri = ExternalLinks.calendarEvent(
        title: 'x',
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 1, 1),
        location: '',
      );

      expect(uri.queryParameters.containsKey('location'), isFalse);
      expect(uri.queryParameters.containsKey('details'), isFalse);
    });

    test('un título con espacios, tildes y & viaja codificado y se lee igual', () {
      final uri = ExternalLinks.calendarEvent(
        title: 'Niños & Niñas vs Pumas',
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 1, 1),
      );

      expect(Uri.parse(uri.toString()).queryParameters['text'], 'Niños & Niñas vs Pumas');
    });
  });

  group('ExternalLinks.directionsTo', () {
    test('arma la ruta hasta el punto del mapa', () {
      final uri = ExternalLinks.directionsTo(latitude: -0.18, longitude: -78.46);

      expect(uri.host, 'www.google.com');
      expect(uri.path, '/maps/dir/');
      expect(uri.queryParameters, {'api': '1', 'destination': '-0.18,-78.46'});
    });
  });
}
