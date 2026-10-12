import 'package:flutter/material.dart';

/// Llave global del `Navigator` de la app. Permite navegar desde fuera del árbol de
/// widgets, p. ej. al expirar la sesión en medio de una petición HTTP.
class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
}
