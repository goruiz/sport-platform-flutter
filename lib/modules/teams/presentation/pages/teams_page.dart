import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/home/presentation/widgets/placeholder_tab.dart';

class TeamsPage extends StatelessWidget {
  final MenuItemModel item;

  const TeamsPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundEnd,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: Text(item.name, style: const TextStyle(color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
        elevation: 0,
      ),
      body: PlaceholderTab(item: item),
    );
  }
}
