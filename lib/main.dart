import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sport_platform/core/constants/strings_constants/app_strings_constants.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/modules/modules_setup.dart';
import 'package:sport_platform/core/routes/app_navigator.dart';
import 'package:sport_platform/core/services/auth_storage.dart';
import 'package:sport_platform/core/services/locale_storage.dart';
import 'package:sport_platform/core/services/user_session.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_theme.dart';
import 'package:sport_platform/modules/auth/presentation/pages/login_page.dart';
import 'package:sport_platform/modules/auth/presentation/pages/password_recovery_page.dart';
import 'package:sport_platform/modules/home/presentation/pages/home_page.dart';
import 'package:sport_platform/modules/players/presentation/pages/invite_register_page.dart';
import 'package:sport_platform/modules/users/presentation/providers/email_verification_notifier.dart';
import 'package:sport_platform/shared/widgets/app_snackbar.dart';
import 'package:sport_platform/shared/widgets/app_viewport.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  // Los nombres de días y meses («mié, 12 nov») de las fechas que se escriben en el idioma del usuario.
  await initializeDateFormatting();
  setupServiceLocator();
  registerModules();
  final startLocale = await LocaleStorage.load();
  EasyLocalization.logger.enableBuildModes = [];
  runApp(
    EasyLocalization(
      supportedLocales: LocaleStorage.supportedLocales,
      path: 'assets/translations',
      fallbackLocale: LocaleStorage.defaultLocale,
      // El idioma que el usuario eligió la última vez (español si nunca eligió).
      startLocale: startLocale,
      child: const SportsPlatform(),
    ),
  );
}

class SportsPlatform extends StatelessWidget {
  const SportsPlatform({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: AppNavigator.key,
      theme: AppTheme.sportsPlatform,
      onGenerateTitle: (ctx) => AppStringsConstants.appName.tr(),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      builder: (context, child) => AppViewport(child: child ?? const SizedBox.shrink()),
      home: const _AppRouter(),
    );
  }
}

class _AppRouter extends StatefulWidget {
  const _AppRouter();

  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  StreamSubscription<Uri>? _linkSubscription;

  // Token from a cold-start deep link, pending navigation after first frame.
  String? _pendingInviteToken;
  String? _pendingPasswordResetToken;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // On web, app_links does not intercept the browser URL.
    // Read Uri.base directly because app_links does not intercept browser URLs.
    if (kIsWeb) {
      final webUri = Uri.base;
      // Normalize path: collapse any leading double-slash (e.g. //register → /register)
      final normalizedPath = '/${webUri.path.replaceAll(RegExp(r'^/+'), '')}';
      final normalized = webUri.replace(path: normalizedPath);
      _handleLink(normalized, isInitial: true);
      return;
    }

    final appLinks = AppLinks();

    // Cold start: check if the app was launched from an invitation or reset link.
    try {
      final initial = await appLinks.getInitialLink();
      if (initial != null) _handleLink(initial, isInitial: true);
    } catch (_) {}

    // Foreground: handle links received while the app is running.
    _linkSubscription = appLinks.uriLinkStream.listen(
      _handleLink,
      onError: (_) {},
    );
  }

  void _handleLink(Uri uri, {bool isInitial = false}) {
    final emailVerificationToken = _extractEmailVerificationToken(uri);
    if (emailVerificationToken != null) {
      // Con la app recién abierta el Navigator aún no existe: se confirma tras el primer cuadro.
      WidgetsBinding.instance.addPostFrameCallback((_) => _confirmEmail(emailVerificationToken));
      return;
    }

    final passwordResetToken = _extractPasswordResetToken(uri);
    if (passwordResetToken != null) {
      if (isInitial) {
        if (mounted) {
          setState(() => _pendingPasswordResetToken = passwordResetToken);
        }
      } else {
        _navigateToPasswordReset(passwordResetToken);
      }
      return;
    }

    final inviteToken = _extractInviteToken(uri);
    if (inviteToken == null) return;
    if (isInitial) {
      // Defer until after the first frame so Navigator is ready.
      if (mounted) setState(() => _pendingInviteToken = inviteToken);
    } else {
      _navigateToInviteRegister(inviteToken);
    }
  }

  /// Extracts the inviteToken from the URI if the path is /register.
  /// Handles:
  ///   http://localhost:5021/register?inviteToken=...   (Android dev)
  ///   sportplatform://register?inviteToken=...         (iOS custom scheme)
  ///   https://yourdomain.com/register?inviteToken=...  (production)
  String? _extractInviteToken(Uri uri) {
    if (uri.path == '/register' || uri.host == 'register') {
      return uri.queryParameters['inviteToken'];
    }
    return null;
  }

  /// El token del enlace del correo de confirmación: `…/verify-email?token=…` o `sportplatform://verify-email?token=…`.
  String? _extractEmailVerificationToken(Uri uri) {
    if (uri.path == '/verify-email' || uri.host == 'verify-email') {
      final token = uri.queryParameters['token'];
      return (token == null || token.isEmpty) ? null : token;
    }
    return null;
  }

  Future<void> _confirmEmail(String token) async {
    final messageKey = await getIt<EmailVerificationNotifier>().confirmWithToken(token);
    final context = AppNavigator.key.currentContext;
    if (context == null || !context.mounted) return;
    final text = messageKey.tr();
    messageKey == 'verify_email.confirmed'
        ? AppSnackbar.success(context, text)
        : AppSnackbar.warning(context, text);
  }

  String? _extractPasswordResetToken(Uri uri) {
    if (uri.path == '/reset-password' || uri.host == 'reset-password') {
      return uri.queryParameters['token'] ?? '';
    }
    return null;
  }

  void _navigateToInviteRegister(String token) {
    AppNavigator.key.currentState?.push(
      MaterialPageRoute(builder: (_) => InviteRegisterPage(inviteToken: token)),
    );
  }

  void _navigateToPasswordReset(String token) {
    AppNavigator.key.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ResetPasswordPage(
          token: token,
          onBack: () {
            AppNavigator.key.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
          },
          onCompleted: () {
            AppNavigator.key.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<bool> _initSession() async {
    final hasToken = await AuthStorage.hasToken();
    if (hasToken) await UserSession.loadFromStorage();
    return hasToken;
  }

  @override
  Widget build(BuildContext context) {
    if (_pendingPasswordResetToken != null) {
      final token = _pendingPasswordResetToken!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _pendingPasswordResetToken = null);
        _navigateToPasswordReset(token);
      });
    }

    // Handle incoming links after the first frame so Navigator is ready.
    if (_pendingInviteToken != null) {
      final token = _pendingInviteToken!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _pendingInviteToken = null);
        _navigateToInviteRegister(token);
      });
    }

    return FutureBuilder<bool>(
      future: _initSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundEnd,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryLight),
            ),
          );
        }
        return snapshot.data == true ? const HomePage() : const LoginPage();
      },
    );
  }
}
