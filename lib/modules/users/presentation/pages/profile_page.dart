import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/strings_constants/logout_strings_constants.dart';
import 'package:sport_platform/core/services/user_session.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/users/domain/entities/user_entity.dart';
import 'package:sport_platform/modules/users/presentation/pages/change_password_page.dart';
import 'package:sport_platform/modules/users/presentation/pages/complete_profile_page.dart';
import 'package:sport_platform/modules/users/presentation/pages/delete_account_page.dart';
import 'package:sport_platform/shared/enums/app_language.dart';
import 'package:sport_platform/shared/widgets/app_card.dart';
import 'package:sport_platform/shared/widgets/app_snackbar.dart';
import 'package:sport_platform/shared/widgets/language_sheet.dart';
import 'package:sport_platform/shared/widgets/logout_flow.dart';

/// El perfil: quién es el usuario, sus datos, sus preferencias (idioma) y las acciones de su cuenta
/// (cambiar la contraseña, cerrar sesión, eliminarla).
class ProfilePage extends StatefulWidget {
  final MenuItemModel item;

  const ProfilePage({super.key, required this.item});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final Future<void> _sessionLoaded;

  @override
  void initState() {
    super.initState();
    _sessionLoaded = UserSession.loadFromStorage();
  }

  Future<void> _editProfile() async {
    final updated = await Navigator.of(context).push<UserEntity>(
      MaterialPageRoute(
        builder: (_) => const CompleteProfilePage(editing: true),
      ),
    );
    if (!mounted || updated == null) return;
    setState(() {});
    AppSnackbar.success(context, 'profile.save_success'.tr());
  }

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Scaffold(
      appBar: AppBar(title: Text(widget.item.localizedName)),
      body: FutureBuilder<void>(
        future: _sessionLoaded,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = UserSession.current;
          if (user == null) {
            return Center(
              child: Text('mobile.profile.load_error'.tr(), style: AppTextStyles.bodyMuted),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.lg,
              AppSpacing.page,
              AppSpacing.listBottom,
            ),
            children: [
              _ProfileHeader(user: user, onEdit: _editProfile),
              const SizedBox(height: AppSpacing.xxl),
              _buildPersonalData(user),
              const SizedBox(height: AppSpacing.xxl),
              _buildPreferences(),
              const SizedBox(height: AppSpacing.xxl),
              _buildAccount(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPersonalData(UserEntity user) {
    return _Section(
      title: 'mobile.profile.section_personal'.tr(),
      children: [
        _InfoRow(label: 'mobile.profile.username'.tr(), value: user.username),
        _InfoRow(label: 'mobile.profile.first_name'.tr(), value: user.firstName),
        _InfoRow(label: 'mobile.profile.middle_name'.tr(), value: user.middleName),
        _InfoRow(label: 'mobile.profile.last_name'.tr(), value: user.lastName),
        _InfoRow(label: 'mobile.profile.second_last_name'.tr(), value: user.secondLastName),
      ],
    );
  }

  Widget _buildPreferences() {
    final language = AppLanguage.fromCode(context.locale.languageCode);
    return _Section(
      title: 'mobile.profile.section_preferences'.tr(),
      children: [
        _ActionRow(
          icon: Icons.language,
          label: 'mobile.profile.language'.tr(),
          value: '${language.flag}  ${language.nativeName}',
          onTap: () => showLanguageSheet(context),
        ),
      ],
    );
  }

  Widget _buildAccount() {
    return _Section(
      title: 'mobile.profile.section_account'.tr(),
      children: [
        _ActionRow(
          icon: Icons.lock_reset_outlined,
          label: 'account.change_password.title'.tr(),
          onTap: () => _open(const ChangePasswordPage()),
        ),
        _ActionRow(
          icon: Icons.logout,
          label: LogoutStringsConstants.button.tr(),
          onTap: () => confirmAndLogOut(context),
        ),
        _ActionRow(
          icon: Icons.delete_outline,
          label: 'account.delete.title'.tr(),
          color: AppColors.error,
          onTap: () => _open(const DeleteAccountPage()),
        ),
      ],
    );
  }
}

/// Un bloque con título: las filas van juntas en una sola tarjeta, separadas por una línea fina.
class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.sm),
          child: Text(title.toUpperCase(), style: AppTextStyles.overline),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Un dato de solo lectura: su nombre pequeño y el valor al lado. Un dato vacío se muestra con un guion.
class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(label, style: AppTextStyles.caption)),
          Expanded(
            flex: 6,
            child: Text(
              hasValue ? value! : '—',
              textAlign: TextAlign.end,
              style: AppTextStyles.body.copyWith(
                color: hasValue ? AppColors.white : AppColors.whiteSubtle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Una fila tocable: icono, nombre, el valor actual (si lo hay) y una flecha.
class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;
  final Color color;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.color = AppColors.white,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.touchTarget + 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: color == AppColors.white ? AppColors.primaryLight : color,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(label, style: AppTextStyles.body.copyWith(color: color)),
              ),
              if (value != null) ...[
                Text(value!, style: AppTextStyles.caption),
                const SizedBox(width: AppSpacing.xs),
              ],
              Icon(Icons.chevron_right, color: color.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserEntity user;
  final VoidCallback onEdit;

  const _ProfileHeader({required this.user, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final name = user.fullName.isEmpty
        ? 'mobile.profile.incomplete'.tr()
        : user.fullName;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary.withValues(alpha: 0.25),
            child: Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.primaryLight,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(name, textAlign: TextAlign.center, style: AppTextStyles.pageTitle),
          if (user.email?.isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(user.email!, textAlign: TextAlign.center, style: AppTextStyles.bodyMuted),
          ],
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text('mobile.profile.edit'.tr()),
          ),
        ],
      ),
    );
  }
}
