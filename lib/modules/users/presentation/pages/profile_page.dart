import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/strings_constants/logout_strings_constants.dart';
import 'package:sport_platform/core/constants/app_constants.dart';
import 'package:sport_platform/core/di/service_locator.dart';
import 'package:sport_platform/core/services/user_session.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/rankings/data/datasource/player_stats_service.dart';
import 'package:sport_platform/modules/users/data/datasource/image_picker_photo_picker.dart';
import 'package:sport_platform/modules/users/data/datasource/player_photo_service.dart';
import 'package:sport_platform/modules/users/domain/profile_photo_picker.dart';
import 'package:sport_platform/modules/users/domain/entities/user_entity.dart';
import 'package:sport_platform/modules/users/presentation/pages/change_password_page.dart';
import 'package:sport_platform/modules/users/presentation/pages/complete_profile_page.dart';
import 'package:sport_platform/modules/users/presentation/pages/delete_account_page.dart';
import 'package:sport_platform/modules/users/presentation/providers/profile_photo_notifier.dart';
import 'package:sport_platform/modules/users/presentation/providers/profile_summary_notifier.dart';
import 'package:sport_platform/modules/users/presentation/widgets/profile_avatar.dart';
import 'package:sport_platform/modules/users/presentation/widgets/profile_photo_sheet.dart';
import 'package:sport_platform/modules/users/presentation/widgets/profile_section.dart';
import 'package:sport_platform/modules/users/presentation/widgets/profile_stats_section.dart';
import 'package:sport_platform/modules/users/presentation/widgets/profile_team_section.dart';
import 'package:sport_platform/shared/enums/app_language.dart';
import 'package:sport_platform/shared/widgets/app_card.dart';
import 'package:sport_platform/shared/widgets/app_snackbar.dart';
import 'package:sport_platform/shared/widgets/language_sheet.dart';
import 'package:sport_platform/shared/widgets/logout_flow.dart';

/// El perfil: quién es el usuario, su equipo y estadísticas, sus datos, sus preferencias (idioma) y las acciones de
/// su cuenta (cambiar la contraseña, cerrar sesión, eliminarla).
class ProfilePage extends StatefulWidget {
  final MenuItemModel item;

  const ProfilePage({super.key, required this.item});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final Future<void> _sessionLoaded;
  late final ProfileSummaryNotifier _summary;
  late final ProfilePhotoNotifier _photo;

  @override
  void initState() {
    super.initState();
    _sessionLoaded = UserSession.loadFromStorage();
    _summary = ProfileSummaryNotifier(
      playersService: getIt<PlayersService>(),
      playerStatsService: getIt<PlayerStatsService>(),
    )..load();
    _photo = ProfilePhotoNotifier(
      service: getIt<PlayerPhotoService>(),
      picker: ImagePickerPhotoPicker(),
    );
  }

  @override
  void dispose() {
    _summary.dispose();
    _photo.dispose();
    super.dispose();
  }

  /// Pregunta qué hacer con la foto (tomarla, elegirla o quitarla), lo hace y avisa cómo terminó.
  Future<void> _changePhoto() async {
    final action = await showProfilePhotoSheet(
      context,
      hasPhoto: _summary.player?.profilePhotoUrl?.isNotEmpty ?? false,
    );
    if (action == null) return;
    final outcome = switch (action) {
      ProfilePhotoAction.takePhoto => await _photo.choose(PhotoSource.camera),
      ProfilePhotoAction.chooseFromGallery => await _photo.choose(PhotoSource.gallery),
      ProfilePhotoAction.remove => await _photo.remove(),
    };
    if (!mounted) return;
    final updatedPlayer = outcome.player;
    if (updatedPlayer != null) _summary.replacePlayer(updatedPlayer);
    final messageKey = outcome.messageKey;
    if (messageKey == null) return;
    outcome.isSuccess
        ? AppSnackbar.success(context, messageKey.tr())
        : AppSnackbar.error(context, messageKey.tr(args: [AppConstants.profilePhotoMaxMegabytes.asText]));
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
          return RefreshIndicator(
            onRefresh: _summary.load,
            color: AppColors.primaryLight,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.lg,
                AppSpacing.page,
                AppSpacing.listBottom,
              ),
              children: [
                _buildHeader(user),
                const SizedBox(height: AppSpacing.xxl),
                _buildTeamSummary(),
                _buildPersonalData(user),
                const SizedBox(height: AppSpacing.xxl),
                _buildPreferences(),
                const SizedBox(height: AppSpacing.xxl),
                _buildAccount(),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Quién es: su foto (que se cambia desde aquí si ya tiene perfil de jugador), su nombre y su correo.
  Widget _buildHeader(UserEntity user) {
    return ListenableBuilder(
      listenable: Listenable.merge([_summary, _photo]),
      builder: (context, _) => _ProfileHeader(
        user: user,
        photoUrl: _summary.player?.profilePhotoUrl,
        isPhotoBusy: _photo.isWorking,
        onEdit: _editProfile,
        // Sin jugador (la cuenta aún no lo tiene o no se pudo leer) no hay dónde guardar la foto.
        onChangePhoto: _summary.player == null ? null : _changePhoto,
      ),
    );
  }

  /// Su equipo y, si tiene uno, sus estadísticas; cada bloque dice si carga, falló o está vacío.
  Widget _buildTeamSummary() {
    return ListenableBuilder(
      listenable: _summary,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileTeamSection(
            status: _summary.teamStatus,
            player: _summary.player,
            onRetry: _summary.load,
          ),
          const SizedBox(height: AppSpacing.xxl),
          if (_summary.hasTeam) ...[
            ProfileStatsSection(
              status: _summary.statsStatus,
              stats: _summary.totalStats,
              onRetry: _summary.load,
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonalData(UserEntity user) {
    return ProfileSection(
      title: 'mobile.profile.section_personal'.tr(),
      children: [
        ProfileInfoRow(label: 'mobile.profile.username'.tr(), value: user.username),
        ProfileInfoRow(label: 'mobile.profile.first_name'.tr(), value: user.firstName),
        ProfileInfoRow(label: 'mobile.profile.middle_name'.tr(), value: user.middleName),
        ProfileInfoRow(label: 'mobile.profile.last_name'.tr(), value: user.lastName),
        ProfileInfoRow(label: 'mobile.profile.second_last_name'.tr(), value: user.secondLastName),
      ],
    );
  }

  Widget _buildPreferences() {
    final language = AppLanguage.fromCode(context.locale.languageCode);
    return ProfileSection(
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
    return ProfileSection(
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
  final String? photoUrl;
  final bool isPhotoBusy;
  final VoidCallback onEdit;
  final VoidCallback? onChangePhoto;

  const _ProfileHeader({
    required this.user,
    required this.photoUrl,
    required this.isPhotoBusy,
    required this.onEdit,
    required this.onChangePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final name = user.fullName.isEmpty
        ? 'mobile.profile.incomplete'.tr()
        : user.fullName;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          ProfileAvatar(
            name: name,
            photoUrl: photoUrl,
            isBusy: isPhotoBusy,
            onTap: onChangePhoto,
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
