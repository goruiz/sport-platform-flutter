import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/strings_constants/home_strings_constants.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/home/presentation/enums/menu_style.dart';
import 'package:sport_platform/modules/home/presentation/widgets/activity_card.dart';
import 'package:sport_platform/modules/home/presentation/widgets/drawer_hint_card.dart';
import 'package:sport_platform/modules/home/presentation/widgets/greeting_banner.dart';
import 'package:sport_platform/modules/home/presentation/widgets/invitations_card.dart';
import 'package:sport_platform/modules/home/presentation/widgets/next_event_card.dart';
import 'package:sport_platform/modules/home/presentation/widgets/quick_actions_carousel.dart';
import 'package:sport_platform/modules/home/presentation/widgets/section_header.dart';
import 'package:sport_platform/modules/home/presentation/widgets/teams_card.dart';

class HomeTab extends StatelessWidget {
  final HomeMenuStyle menuStyle;
  final List<MenuItemModel> menuItems;
  final bool isLoadingMenu;
  final bool menuError;
  final VoidCallback onRetryMenu;

  const HomeTab({
    super.key,
    required this.menuStyle,
    required this.menuItems,
    required this.isLoadingMenu,
    required this.menuError,
    required this.onRetryMenu,
  });

  @override
  Widget build(BuildContext context) {
    context.locale;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 20, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: GreetingBanner(),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SectionHeader(
              title: HomeStringsConstants.sectionQuickActions.tr(),
            ),
          ),
          const SizedBox(height: 12),
          if (menuStyle == HomeMenuStyle.carousel)
            QuickActionsCarousel(
              items: menuItems,
              isLoading: isLoadingMenu,
              hasError: menuError,
              onRetry: onRetryMenu,
            )
          else
            Builder(
              builder: (ctx) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: DrawerHintCard(
                  onTap: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
            ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SectionHeader(
              title: HomeStringsConstants.sectionInvitations.tr(),
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: InvitationsCard(),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SectionHeader(
              title: HomeStringsConstants.sectionNextEvent.tr(),
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: NextEventCard(),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SectionHeader(
              title: HomeStringsConstants.sectionActiveTeams.tr(),
              trailing: HomeStringsConstants.viewAll.tr(),
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: TeamsCard(),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SectionHeader(
              title: HomeStringsConstants.sectionRecentActivity.tr(),
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: ActivityCard(),
          ),
        ],
      ),
    );
  }
}
