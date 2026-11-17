import 'package:flutter/widgets.dart';

/// Las pantallas a las que se llega desde módulos que no deben importarse entre sí: el login lleva al inicio, el
/// registro al perfil, cerrar la sesión al login… Cada módulo pide la pantalla aquí y [registerModules] dice cuál es,
/// así dos módulos nunca quedan importándose en círculo solo por navegar de uno a otro (como [SessionExpiredListener],
/// la interfaz vive en `core` y quien la completa es el ensamblaje).
class AppPages {
  AppPages._();

  static Widget Function()? _login;
  static Widget Function()? _home;
  static Widget Function({required bool editing})? _completeProfile;

  /// Dice qué pantalla es cada una. Se llama una vez al arrancar, desde `registerModules`.
  static void register({
    required Widget Function() login,
    required Widget Function() home,
    required Widget Function({required bool editing}) completeProfile,
  }) {
    _login = login;
    _home = home;
    _completeProfile = completeProfile;
  }

  static Widget login() => _registered(_login, 'login')();

  static Widget home() => _registered(_home, 'home')();

  /// El formulario del perfil. Con [editing] la persona ya tenía su perfil completo y lo está corrigiendo.
  static Widget completeProfile({bool editing = false}) =>
      _registered(_completeProfile, 'completeProfile')(editing: editing);

  static T _registered<T>(T? builder, String name) {
    if (builder == null) {
      throw StateError('AppPages: la pantalla «$name» no está registrada; llama a registerModules() al arrancar.');
    }
    return builder;
  }
}
