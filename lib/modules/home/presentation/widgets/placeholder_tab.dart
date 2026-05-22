import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';

class PlaceholderTab extends StatelessWidget {
  final int index;

  const PlaceholderTab({super.key, required this.index});

  static const _icons = [
    Icons.home,
    Icons.group,
    Icons.event,
    Icons.leaderboard,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        _icons[index],
        color: AppColors.whiteSubtle,
        size: 48,
      ),
    );
  }
}
