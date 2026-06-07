import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/strings_constants/app_strings_constants.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/modules/modules_setup.dart';
import 'package:sport_platform/core/services/auth_storage.dart';
import 'package:sport_platform/core/services/user_session.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_theme.dart';
import 'package:sport_platform/modules/auth/presentation/pages/login_page.dart';
import 'package:sport_platform/modules/home/presentation/pages/home_page.dart';
import 'package:sport_platform/modules/players/presentation/pages/invite_register_page.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  setupServiceLocator();
  registerModules();
  EasyLocalization.logger.enableBuildModes = [];
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
        Locale('fr'),
        Locale('de'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('es'),
      startLocale: const Locale('es'),
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
      navigatorKey: _navigatorKey,
      theme: AppTheme.sportsPlatform,
      onGenerateTitle: (ctx) => AppStringsConstants.appName.tr(),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
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

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    final appLinks = AppLinks();

    // Cold start: check if the app was launched from an invite link.
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
    final token = _extractToken(uri);
    if (token == null) return;

    if (isInitial) {
      // Defer until after the first frame so Navigator is ready.
      if (mounted) setState(() => _pendingInviteToken = token);
    } else {
      _navigateToInviteRegister(token);
    }
  }

  /// Extracts the inviteToken from the URI if the path is /register.
  /// Handles:
  ///   http://localhost:5021/register?inviteToken=...   (Android dev)
  ///   sportplatform://register?inviteToken=...         (iOS custom scheme)
  ///   https://yourdomain.com/register?inviteToken=...  (production)
  String? _extractToken(Uri uri) {
    if (uri.path == '/register') {
      return uri.queryParameters['inviteToken'];
    }
    return null;
  }

  void _navigateToInviteRegister(String token) {
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => InviteRegisterPage(inviteToken: token),
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
    // Navigate to InviteRegisterPage after the first frame if there's a
    // pending cold-start token.
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
