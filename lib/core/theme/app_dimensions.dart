/// Separaciones de la interfaz: todo margen, relleno o espacio entre elementos sale de aquí
/// para que todas las pantallas respiren igual.
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;

  /// Espacio entre los bloques grandes de una pantalla (las secciones del inicio).
  static const double section = 28;

  /// Margen lateral de casi todas las pantallas.
  static const double page = 16;

  /// Margen inferior de las listas largas, para que el último elemento no quede pegado al borde.
  static const double listBottom = 28;
}

/// Esquinas redondeadas.
class AppRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double pill = 999;
}

/// Tamaños mínimos que garantizan que todo se pueda tocar con el dedo.
class AppSizes {
  /// Alto de los botones principales.
  static const double button = 52;

  /// Lado mínimo de cualquier zona tocable (recomendación de Material y de Apple: 44–48).
  static const double touchTarget = 48;

  /// Ancho máximo del contenido de la app: más ancho que esto (tablet, web, escritorio) se centra una columna.
  static const double maxContentWidth = 600;
}
