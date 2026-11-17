import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/locale_keys.g.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/services/user_session.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
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
    final isSuccess = messageKey == LocaleKeys.verify_email_resent || messageKey == LocaleKeys.verify_email_confirmed;
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
          margin: const EdgeInsets.only(bottom: AppSpacing.xl),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.mark_email_unread_outlined, color: AppColors.warningLight),
                  const SizedBox(width: AppSpacing.snug),
                  Expanded(
                    child: Text(
                      LocaleKeys.verify_email_title.tr(),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                LocaleKeys.verify_email_text.tr(args: [UserSession.current?.email ?? '']),
                style: const TextStyle(color: AppColors.whiteSubtle, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _busy ? null : () => _run(notifier.resend),
                    child: Text(LocaleKeys.verify_email_resend.tr()),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => _run(notifier.checkAgain),
                    child: Text(LocaleKeys.verify_email_check.tr()),
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
