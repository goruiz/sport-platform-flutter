import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sport_platform/core/constants/app_constants.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/services/session_service.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/modules/players/data/datasource/join_team_service.dart';
import 'package:sport_platform/modules/players/domain/enums/join_team_error.dart';
import 'package:sport_platform/shared/widgets/app_snackbar.dart';
import 'package:sport_platform/shared/widgets/sport_text_field.dart';

/// Entrar a un equipo sin esperar una invitación: el administrador del equipo comparte un código y el jugador lo escribe.
/// Se cierra con `true` cuando el jugador entró, para que quien la abrió vuelva a leer lo suyo.
class JoinTeamPage extends StatefulWidget {
  const JoinTeamPage({super.key});

  static Future<bool> open(BuildContext context) async {
    final joined = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const JoinTeamPage()),
    );
    return joined == true;
  }

  @override
  State<JoinTeamPage> createState() => _JoinTeamPageState();
}

class _JoinTeamPageState extends State<JoinTeamPage> {
  final _codeController = TextEditingController();
  bool _joining = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      AppSnackbar.error(context, 'join_team.code_required'.tr());
      return;
    }
    setState(() => _joining = true);
    try {
      final newToken = await getIt<JoinTeamService>().join(code);
      // Entrar cambia el equipo y, con él, la organización de la cuenta: se renueva la sesión para verla.
      if (newToken != null) await getIt<SessionService>().replaceToken(newToken);
      if (!mounted) return;
      AppSnackbar.success(context, 'join_team.success'.tr());
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final reason = JoinTeamError.fromException(error);
      AppSnackbar.error(context, (reason?.translationKey ?? 'join_team.errors.generic').tr());
      setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Scaffold(
      appBar: AppBar(title: Text('join_team.title'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Text('join_team.hint'.tr(), style: AppTextStyles.bodyMuted.copyWith(height: 1.4)),
          const SizedBox(height: AppSpacing.xl),
          SportTextField(
            controller: _codeController,
            hint: 'join_team.field'.tr(),
            icon: Icons.vpn_key_outlined,
            textInputAction: TextInputAction.done,
            // Enter en el teclado entra al equipo: es el único campo de la pantalla.
            onSubmitted: (_) {
              if (!_joining) _join();
            },
            inputFormatters: [
              LengthLimitingTextInputFormatter(AppConstants.joinCodeMaxInputLength),
              // El código es en mayúsculas y sin ambigüedades: se escribe como llega.
              TextInputFormatter.withFunction(
                (oldValue, newValue) => newValue.copyWith(text: newValue.text.toUpperCase()),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl + AppSpacing.xs),
          SizedBox(
            height: AppSizes.button,
            child: FilledButton(
              onPressed: _joining ? null : _join,
              child: _joining
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2.5),
                    )
                  : Text('join_team.submit'.tr()),
            ),
          ),
        ],
      ),
    );
  }
}
