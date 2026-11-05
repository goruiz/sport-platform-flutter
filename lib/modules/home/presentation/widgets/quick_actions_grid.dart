import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/strings_constants/home_strings_constants.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/home/presentation/constants/menu_colors.dart';
import 'package:sport_platform/modules/home/presentation/widgets/quick_action_card.dart';
import 'package:sport_platform/shared/widgets/app_card.dart';
import 'package:sport_platform/shared/widgets/skeleton_box.dart';

/// Los accesos del inicio, todos a la vista (nada escondido detrás de un deslizamiento ni de una hoja).
/// Las opciones de un grupo del menú («Resultados y estadísticas», «Instalaciones») se muestran directamente,
/// bajo el nombre del grupo: a cada pantalla se llega con un solo toque.
/// Se adapta al ancho (3 columnas en un teléfono) y **llena cada fila**: dos opciones se reparten el ancho entre las dos,
/// no se quedan a un lado con un hueco.
class QuickActionsGrid extends StatelessWidget {
  final List<MenuItemModel> items;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onRetry;

  /// El ancho mínimo cómodo de un acceso: decide cuántas columnas caben (3 en un teléfono).
  static const double _minTileWidth = 104;
  static const double _tileHeight = 108;

  /// Desde este ancho el icono y el nombre van uno al lado del otro y la tarjeta es más baja.
  static const double _horizontalTileMinWidth = 150;
  static const double _horizontalTileHeight = 84;
  static const int _loadingTiles = 3;

  const QuickActionsGrid({
    super.key,
    required this.items,
    required this.isLoading,
    required this.hasError,
    required this.onRetry,
  });

  /// Reparte el menú en bloques: las opciones sueltas que van seguidas forman un bloque sin título y cada
  /// grupo forma el suyo, con su nombre. El orden del menú se respeta.
  @visibleForTesting
  static List<QuickActionsSection> buildSections(List<MenuItemModel> items) {
    final sections = <QuickActionsSection>[];
    final looseItems = <MenuItemModel>[];

    void flushLooseItems() {
      if (looseItems.isEmpty) return;
      sections.add(QuickActionsSection(title: null, items: List.of(looseItems)));
      looseItems.clear();
    }

    for (final item in items) {
      if (item.hasChildren) {
        flushLooseItems();
        sections.add(QuickActionsSection(title: item.localizedName, items: item.children));
      } else {
        looseItems.add(item);
      }
    }
    flushLooseItems();
    return sections;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildLoading(context);
    if (hasError) return _buildError();
    if (items.isEmpty) return _buildEmpty();

    // Los colores siguen corriendo entre bloques para que no se repitan en cada uno.
    final children = <Widget>[];
    var firstColorIndex = 0;
    for (final section in buildSections(items)) {
      if (children.isNotEmpty) children.add(const SizedBox(height: AppSpacing.lg));
      if (section.title != null) children.add(_buildSectionTitle(section.title!));
      children.add(_buildGrid(context, section.items, firstColorIndex));
      firstColorIndex += section.items.length;
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.sm),
      child: Text(title, style: AppTextStyles.caption),
    );
  }

  Widget _buildGrid(BuildContext context, List<MenuItemModel> tiles, int firstColorIndex) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = columnsFor(tiles.length, constraints.maxWidth);
        final tileWidth = (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;
        final horizontal = tileWidth >= _horizontalTileMinWidth;
        final tileHeight = horizontal ? _horizontalTileHeight : _tileHeight;
        final textScale = math.max(1.0, MediaQuery.textScalerOf(context).scale(1));
        final rows = <Widget>[];
        for (var start = 0; start < tiles.length; start += columns) {
          final end = math.min(start + columns, tiles.length);
          if (rows.isNotEmpty) rows.add(const SizedBox(height: AppSpacing.md));
          rows.add(
            SizedBox(
              height: tileHeight * textScale,
              child: Row(
                children: [
                  for (var i = start; i < end; i++) ...[
                    if (i > start) const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: QuickActionCard(
                        item: tiles[i],
                        horizontal: horizontal,
                        color: kMenuColors[(firstColorIndex + i) % kMenuColors.length],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return Column(children: rows);
      },
    );
  }

  /// Cuántas columnas usar para [count] accesos en [width] píxeles: las que caben, repartidas en filas parejas
  /// (4 accesos en 3 columnas serían 3 + 1; en 2 columnas son 2 + 2) para que ninguna fila quede casi vacía.
  @visibleForTesting
  static int columnsFor(int count, double width) {
    if (count <= 1) return 1;
    final fitting = math.max(1, ((width + AppSpacing.md) / (_minTileWidth + AppSpacing.md)).floor());
    final rows = (count / fitting).ceil();
    return (count / rows).ceil();
  }

  Widget _buildLoading(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: _loadingTiles,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.15,
      children: List.generate(
        _loadingTiles,
        (_) => const SkeletonBox(height: _tileHeight),
      ),
    );
  }

  Widget _buildError() {
    return AppCard(
      onTap: onRetry,
      child: Row(
        children: [
          const Icon(Icons.refresh, color: AppColors.primaryLight, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(HomeStringsConstants.menuError.tr(), style: AppTextStyles.bodyMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.apps_outlined, color: AppColors.whiteSubtle, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(HomeStringsConstants.menuEmpty.tr(), style: AppTextStyles.bodyMuted),
          ),
        ],
      ),
    );
  }
}

/// Un bloque de accesos: opcionalmente con el nombre del grupo del que vienen.
class QuickActionsSection {
  final String? title;
  final List<MenuItemModel> items;

  const QuickActionsSection({required this.title, required this.items});
}
