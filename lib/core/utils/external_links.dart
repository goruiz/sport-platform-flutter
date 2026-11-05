/// Enlaces que se abren fuera de la app (el calendario y el mapa). Son funciones puras: arman la dirección y otra capa
/// la abre, así se pueden probar sin un dispositivo.
class ExternalLinks {
  ExternalLinks._();

  /// Un evento nuevo en Google Calendar con los datos ya puestos. Las horas van sin zona (la del dispositivo), igual que
  /// el partido las guarda; abre la web o la app de Calendar en cualquier plataforma, sin otro plugin.
  static Uri calendarEvent({
    required String title,
    required DateTime start,
    required DateTime end,
    String? location,
    String? details,
  }) {
    return Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': title,
      'dates': '${_calendarStamp(start)}/${_calendarStamp(end)}',
      if (location != null && location.isNotEmpty) 'location': location,
      if (details != null && details.isNotEmpty) 'details': details,
    });
  }

  /// Cómo llegar a un punto del mapa: abre Google Maps con la ruta hasta ahí.
  static Uri directionsTo({required double latitude, required double longitude}) {
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$latitude,$longitude',
    });
  }

  /// `20261105T183000`: lo que Calendar espera para una fecha y hora locales.
  static String _calendarStamp(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}${two(date.month)}${two(date.day)}'
        'T${two(date.hour)}${two(date.minute)}${two(date.second)}';
  }
}
