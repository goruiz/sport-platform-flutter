/// El estado de un evento. El backend lo guarda como texto libre: solo estos cuatro valores los
/// entienden las dos apps y el panel.
enum EventStatus {
  upcoming('UPCOMING'),
  active('ACTIVE'),
  finished('FINISHED'),
  cancelled('CANCELLED');

  const EventStatus(this.apiValue);

  final String apiValue;

  /// Null si el texto no es uno de los cuatro (el backend no lo valida).
  static EventStatus? fromApi(String? value) {
    final normalized = value?.toUpperCase();
    for (final status in values) {
      if (status.apiValue == normalized) return status;
    }
    return null;
  }
}
