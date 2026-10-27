/// Dónde está una etapa del campeonato (`PhaseStatus` del backend).
enum PhaseStatus {
  /// La etapa anterior no terminó: esta aún no puede empezar.
  pending('PENDING'),

  /// Puede empezar: todavía no se generó nada para ella.
  ready('READY'),
  inProgress('IN_PROGRESS'),
  finished('FINISHED');

  const PhaseStatus(this.apiValue);

  final String apiValue;

  /// Un estado desconocido se trata como pendiente: es el que menos afirma.
  static PhaseStatus fromApi(String? value) {
    for (final status in values) {
      if (status.apiValue == value) return status;
    }
    return pending;
  }
}
