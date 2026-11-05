import 'package:flutter/material.dart';
import 'package:sport_platform/core/routes/app_route_factory.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/home/presentation/widgets/children_sheet.dart';

/// Un acceso del inicio: una tarjeta con un destello del color de su acento, el icono en una pastilla de ese color
/// y su nombre. Si la opción tiene otras dentro (un grupo) lo indica con una flechita y, al tocarla,
/// las muestra en una hoja inferior.
///
/// En una tarjeta estrecha el icono va arriba y el nombre abajo; en una ancha ([horizontal]) van uno al lado del
/// otro, para no dejar un hueco vacío en medio.
class QuickActionCard extends StatelessWidget {
  final MenuItemModel item;
  final Color color;
  final bool horizontal;

  const QuickActionCard({
    super.key,
    required this.item,
    required this.color,
    this.horizontal = false,
  });

  void _onTap(BuildContext context) {
    if (item.hasChildren) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => ChildrenSheet(
          parent: item,
          parentColor: color,
          onNavigate: (child) => AppRouteFactory.navigateTo(context, child),
        ),
      );
    } else {
      AppRouteFactory.navigateTo(context, item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.md);
    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: radius,
          // El color entra por una esquina y se funde con la superficie: da vida sin ensuciar la tarjeta.
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.22), AppColors.inputFill],
          ),
          border: Border.all(color: color.withValues(alpha: 0.32)),
        ),
        child: InkWell(
          onTap: () => _onTap(context),
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: horizontal ? _buildHorizontal() : _buildVertical(),
          ),
        ),
      ),
    );
  }

  Widget _buildVertical() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildIconRow(),
        _buildName(),
      ],
    );
  }

  Widget _buildHorizontal() {
    return Row(
      children: [
        _buildIconBox(),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _buildName()),
        if (item.hasChildren) Icon(Icons.expand_more, color: color, size: 22),
      ],
    );
  }

  Widget _buildIconBox() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.sm + 2),
      ),
      child: Icon(MenuItemModel.iconFromString(item.icon), color: color, size: 24),
    );
  }

  Widget _buildIconRow() {
    return Row(
      children: [
        _buildIconBox(),
        const Spacer(),
        if (item.hasChildren) Icon(Icons.expand_more, color: color, size: 22),
      ],
    );
  }

  Widget _buildName() {
    return Text(
      item.localizedName,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.white,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    );
  }
}
