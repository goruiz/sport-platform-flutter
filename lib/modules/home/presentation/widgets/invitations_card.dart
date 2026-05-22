import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/strings_constants/home_strings_constants.dart';
import 'package:sport_platform/modules/home/presentation/widgets/empty_card.dart';

class InvitationsCard extends StatelessWidget {
  const InvitationsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyCard(
      icon: Icons.check_circle_outline,
      message: HomeStringsConstants.noInvitations.tr(),
    );
  }
}
