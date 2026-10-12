/// Contrato para reaccionar a una sesión vencida. La capa de red solo conoce esta
/// interfaz; quién la implementa (navegar al login, avisar al usuario) es cosa de la UI.
abstract interface class SessionExpiredListener {
  Future<void> onSessionExpired();
}
