import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/strings_constants/logout_strings_constants.dart';
import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/core/services/auth_storage.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/auth/presentation/pages/login_page.dart';

class LogoutButton extends StatefulWidget {
  const LogoutButton({super.key});

  @override
  State<LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<LogoutButton> {
  final _client = DioClient();
  bool _isLoading = false;

  Future<void> _onLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.primaryDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          LogoutStringsConstants.title.tr(),
          style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          LogoutStringsConstants.confirm.tr(),
          style: const TextStyle(color: AppColors.whiteSubtle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              LogoutStringsConstants.cancel.tr(),
              style: const TextStyle(color: AppColors.whiteSubtle),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(LogoutStringsConstants.button.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);

    try {
      await _client.post(ApiEndpoints.logout);
    } catch (_) {
      // si falla el endpoint igual limpiamos la sesión local
    } finally {
      await AuthStorage.clearToken();
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    return _isLoading
        ? const Padding(
            padding: EdgeInsets.all(14),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: AppColors.white,
                strokeWidth: 2,
              ),
            ),
          )
        : IconButton(
            icon: const Icon(Icons.logout, color: AppColors.white),
            tooltip: LogoutStringsConstants.tooltip.tr(),
            onPressed: _onLogout,
          );
  }
}
