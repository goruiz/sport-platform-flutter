import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/services/user_session.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/users/presentation/providers/email_verification_notifier.dart';
import 'package:sport_platform/shared/widgets/app_snackbar.dart';

/// El aviso de que el correo aún no está confirmado: sin confirmarlo no se puede entrar a un equipo. No se dibuja
/// nada cuando ya está confirmado o cuando todavía no se sabe.
class EmailVerificationBanner extends StatefulWidget {
  const EmailVerificationBanner({super.key});

  @override
  State<EmailVerificationBanner> createState() => _EmailVerificationBannerState();
}

class _EmailVerificationBannerState extends State<EmailVerificationBanner> {
  bool _busy = false;

  Future<void> _run(Future<String> Function() action) async {
    setState(() => _busy = true);
    final messageKey = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    final isSuccess = messageKey == 'verify_email.resent' || messageKey == 'verify_email.confirmed';
    final text = messageKey.tr();
    isSuccess ? AppSnackbar.success(context, text) : AppSnackbar.warning(context, text);
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    final notifier = getIt<EmailVerificationNotifier>();
    return ListenableBuilder(
      listenable: notifier,
      builder: (context, _) {
        if (!notifier.needsVerification) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.mark_email_unread_outlined, color: AppColors.warningLight),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'verify_email.title'.tr(),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'verify_email.text'.tr(args: [UserSession.current?.email ?? '']),
                style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _busy ? null : () => _run(notifier.resend),
                    child: Text('verify_email.resend'.tr()),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => _run(notifier.checkAgain),
                    child: Text('verify_email.check'.tr()),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
