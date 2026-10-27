import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/services/user_session.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/users/domain/entities/user_entity.dart';
import 'package:sport_platform/modules/users/presentation/pages/complete_profile_page.dart';
import 'package:sport_platform/shared/widgets/app_snackbar.dart';

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

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Scaffold(
      backgroundColor: AppColors.backgroundEnd,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: Text(widget.item.localizedName,
            style: const TextStyle(color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: FutureBuilder<void>(
        future: _sessionLoaded,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryLight),
            );
          }
          final user = UserSession.current;
          if (user == null) {
            return Center(
              child: Text(
                'mobile.profile.load_error'.tr(),
                style: const TextStyle(color: AppColors.whiteSubtle),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _ProfileHeader(user: user),
              const SizedBox(height: 24),
              _ProfileField(
                  icon: Icons.email_outlined,
                  label: 'mobile.profile.email'.tr(),
                  value: user.email ?? '—'),
              _ProfileField(
                  icon: Icons.alternate_email,
                  label: 'mobile.profile.username'.tr(),
                  value: user.username ?? '—'),
              _ProfileField(
                  icon: Icons.badge_outlined,
                  label: 'mobile.profile.first_name'.tr(),
                  value: user.firstName ?? '—'),
              _ProfileField(
                  icon: Icons.badge_outlined,
                  label: 'mobile.profile.middle_name'.tr(),
                  value: user.middleName ?? '—'),
              _ProfileField(
                  icon: Icons.person_outline,
                  label: 'mobile.profile.last_name'.tr(),
                  value: user.lastName ?? '—'),
              _ProfileField(
                  icon: Icons.person_outline,
                  label: 'mobile.profile.second_last_name'.tr(),
                  value: user.secondLastName ?? '—'),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _editProfile,
                  icon: const Icon(Icons.edit_outlined),
                  label: Text('mobile.profile.edit'.tr()),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserEntity user;

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user.fullName.isEmpty
        ? 'mobile.profile.incomplete'.tr()
        : user.fullName;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.primaryLight,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (user.email?.isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            Text(
              user.email!,
              style: const TextStyle(color: AppColors.whiteSubtle),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileField({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: ListTile(
          leading: Icon(icon, color: AppColors.primaryLight),
          title: Text(label,
              style: const TextStyle(
                  color: AppColors.whiteSubtle, fontSize: 12)),
          subtitle: Text(value,
              style: const TextStyle(color: AppColors.white, fontSize: 15)),
        ),
      );
}
