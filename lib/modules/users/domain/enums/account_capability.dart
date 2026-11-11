/// Lo extra que una cuenta puede hacer en la app según su rol (hoy, solo el «Dirigente de equipo» tiene alguna). El
/// backend las manda en `capabilities` de `GET /users/auth/me` y es quien las vuelve a comprobar al ejecutar la acción:
/// la app solo las usa para no ofrecer botones que se van a rechazar.
///
/// Una capacidad nueva se agrega aquí con el código que manda el backend (`AccountCapability`).
enum AccountCapability {
  /// Avisar al organizador de que el resultado de un partido de su equipo parece incorrecto (una «disputa»).
  openMatchDisputes('OPEN_MATCH_DISPUTES');

  const AccountCapability(this.apiValue);

  final String apiValue;

  /// La capacidad de un código del backend; null si la app todavía no la conoce.
  static AccountCapability? fromApi(Object? value) {
    for (final capability in values) {
      if (capability.apiValue == value) return capability;
    }
    return null;
  }

  /// Las capacidades de la lista que manda el backend; ignora las que la app no conoce y todo lo que no sea una lista.
  static Set<AccountCapability> setFrom(Object? raw) {
    if (raw is! List) return const {};
    return {for (final value in raw) ?fromApi(value)};
  }
}
