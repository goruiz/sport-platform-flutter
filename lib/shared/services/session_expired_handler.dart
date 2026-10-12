import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/strings_constants/session_strings_constants.dart';
import 'package:sport_platform/core/services/auth_storage.dart';
import 'package:sport_platform/core/services/session_expired_listener.dart';
import 'package:sport_platform/core/services/session_service.dart';
import 'package:sport_platform/shared/widgets/app_snackbar.dart';

/// Cuando el backend rechaza el token: cierra la sesión local y devuelve al usuario al
/// login, avisándole por qué.
class SessionExpiredHandler implements SessionExpiredListener {
  final SessionService _sessionService;
  final GlobalKey<NavigatorState> _navigatorKey;
  final Widget Function() _loginPageBuilder;

  bool _isHandling = false;

  SessionExpiredHandler({
    required SessionService sessionService,
    required GlobalKey<NavigatorState> navigatorKey,
    required Widget Function() loginPageBuilder,
  })  : _sessionService = sessionService,
        _navigatorKey = navigatorKey,
        _loginPageBuilder = loginPageBuilder;

  @override
  Future<void> onSessionExpired() async {
    // Varias peticiones en vuelo pueden recibir 401 a la vez: solo la primera cierra la sesión.
    if (_isHandling) return;
    _isHandling = true;
    try {
      if (!await AuthStorage.hasToken()) return; // la sesión ya estaba cerrada
      await _sessionService.clear();
      _showLoginPage();
    } finally {
      _isHandling = false;
    }
  }

  void _showLoginPage() {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => _loginPageBuilder()),
      (route) => false,
    );
    // Después del frame, para que no lo tape el aviso de error de la pantalla que se cierra.
    WidgetsBinding.instance.addPostFrameCallback((_) => _announceSessionExpired());
  }

  void _announceSessionExpired() {
    final context = _navigatorKey.currentContext;
    if (context == null) return;
    AppSnackbar.info(context, SessionStringsConstants.expired.tr());
  }
}
