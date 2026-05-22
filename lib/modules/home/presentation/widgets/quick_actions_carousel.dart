import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';
import 'package:sport_platform/modules/home/presentation/constants/menu_colors.dart';
import 'package:sport_platform/modules/home/presentation/widgets/quick_action_card.dart';

class QuickActionsCarousel extends StatefulWidget {
  final List<MenuItemModel> items;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onRetry;

  const QuickActionsCarousel({
    super.key,
    required this.items,
    required this.isLoading,
    required this.hasError,
    required this.onRetry,
  });

  @override
  State<QuickActionsCarousel> createState() => _QuickActionsCarouselState();
}

class _QuickActionsCarouselState extends State<QuickActionsCarousel> {
  late final PageController _controller;
  int _currentPage = 0;

  static const int _itemsPerPage = 3;

  int get _pageCount =>
      (widget.items.length / _itemsPerPage).ceil().clamp(1, 999);

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) return _buildLoading();
    if (widget.hasError) return _buildError();
    if (widget.items.isEmpty) return _buildEmpty();

    return Column(
      children: [
        SizedBox(
          height: 110,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
              },
            ),
            child: PageView.builder(
              controller: _controller,
              itemCount: _pageCount,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (_, pageIndex) {
                final start = pageIndex * _itemsPerPage;
                final end =
                    (start + _itemsPerPage).clamp(0, widget.items.length);
                final pageItems = widget.items.sublist(start, end);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      for (int i = 0; i < pageItems.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(
                          child: QuickActionCard(
                            item: pageItems[i],
                            color: kMenuColors[(start + i) % kMenuColors.length],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _pageCount,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == _currentPage ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == _currentPage
                    ? AppColors.primary
                    : AppColors.whiteSubtle.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return SizedBox(
      height: 110,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: List.generate(3, (i) => [
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.inputBorder),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.primaryLight,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ])
              .expand((e) => e)
              .toList(),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: widget.onRetry,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.refresh, color: AppColors.primaryLight, size: 20),
              SizedBox(width: 8),
              Text(
                'Error al cargar el menú. Toca para reintentar.',
                style: TextStyle(color: AppColors.whiteSubtle, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: const Center(
          child: Text(
            'Sin acciones disponibles',
            style: TextStyle(color: AppColors.whiteSubtle, fontSize: 13),
          ),
        ),
      ),
    );
  }
}
