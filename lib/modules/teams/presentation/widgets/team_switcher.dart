import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';
import 'package:sport_platform/modules/teams/presentation/widgets/team_switcher_card.dart';

/// Elige entre los equipos del jugador (puede jugar en varios, uno por organización): un carrusel con una tarjeta por
/// página, siempre completa y dentro de los márgenes de la pantalla. Se elige deslizando, con las flechas o tocando un
/// punto; los puntos dicen cuántos hay y cuál se ve. Con un solo equipo no hay nada que elegir: es solo su tarjeta.
///
/// La pantalla es dueña de la selección ([selectedTeamId]); el carrusel solo la sigue y avisa con [onSelected].
class TeamSwitcher extends StatefulWidget {
  final List<TeamSwitcherItem> items;
  final String selectedTeamId;
  final ValueChanged<String> onSelected;

  const TeamSwitcher({
    super.key,
    required this.items,
    required this.selectedTeamId,
    required this.onSelected,
  });

  @override
  State<TeamSwitcher> createState() => _TeamSwitcherState();
}

class _TeamSwitcherState extends State<TeamSwitcher> {
  static const Duration _scrollDuration = Duration(milliseconds: 320);

  /// La tarjeta y el aire vertical que necesita su resplandor, que se sale de ella.
  static const double _carouselHeight = TeamSwitcherCard.height + 2 * TeamSwitcherCard.glowMargin;

  late final PageController _pageController;

  int get _selectedIndex {
    final index = widget.items.indexWhere((item) => item.teamId == widget.selectedTeamId);
    return index < 0 ? 0 : index;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void didUpdateWidget(TeamSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    // La pantalla cambió el equipo elegido por su cuenta (no fue un deslizamiento): el carrusel lo acompaña.
    final shownPage = _pageController.hasClients ? _pageController.page?.round() : null;
    if (shownPage != null && shownPage != _selectedIndex) _goToPage(_selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    _pageController.animateToPage(index, duration: _scrollDuration, curve: Curves.easeOutCubic);
  }

  /// Se dispara al cruzar la mitad de un deslizamiento: el detalle cambia mientras la tarjeta aún termina de asentarse.
  void _onPageChanged(int index) {
    final teamId = widget.items[index].teamId;
    if (teamId == widget.selectedTeamId) return;
    HapticFeedback.selectionClick();
    widget.onSelected(teamId);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.length == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: TeamSwitcherCard.glowMargin),
        child: TeamSwitcherCard(item: widget.items.first, isSelected: true),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: _carouselHeight,
          child: PageView.builder(
            controller: _pageController,
            // Sin recorte, para que el resplandor de la tarjeta elegida no se corte arriba ni abajo. Las páginas vecinas
            // quedan fuera de la pantalla, así que no se ven.
            clipBehavior: Clip.none,
            itemCount: widget.items.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: TeamSwitcherCard.glowMargin),
                child: TeamSwitcherCard(
                  key: ValueKey('team-card-${item.teamId}'),
                  item: item,
                  isSelected: item.teamId == widget.selectedTeamId,
                ),
              );
            },
          ),
        ),
        _Navigation(
          count: widget.items.length,
          selectedIndex: _selectedIndex,
          onGoTo: _goToPage,
        ),
      ],
    );
  }
}

/// Las flechas y los puntos bajo el carrusel: son la forma explícita de moverse (además de deslizar) y dicen cuántos
/// equipos hay y cuál se ve.
class _Navigation extends StatelessWidget {
  final int count;
  final int selectedIndex;
  final ValueChanged<int> onGoTo;

  const _Navigation({required this.count, required this.selectedIndex, required this.onGoTo});

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ArrowButton(
          icon: Icons.chevron_left_rounded,
          tooltip: 'mobile.teams.previous_team'.tr(),
          onPressed: selectedIndex > 0 ? () => onGoTo(selectedIndex - 1) : null,
        ),
        ExcludeSemantics(
          child: Row(
            children: [
              for (var index = 0; index < count; index++)
                GestureDetector(
                  onTap: () => onGoTo(index),
                  behavior: HitTestBehavior.opaque,
                  // Zona de toque más grande que el punto, que mide 8.
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: AppSpacing.md),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      width: index == selectedIndex ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        color: index == selectedIndex ? AppColors.primaryLight : AppColors.inputBorder,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        _ArrowButton(
          icon: Icons.chevron_right_rounded,
          tooltip: 'mobile.teams.next_team'.tr(),
          onPressed: selectedIndex < count - 1 ? () => onGoTo(selectedIndex + 1) : null,
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _ArrowButton({required this.icon, required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon),
      color: AppColors.white,
      disabledColor: AppColors.inputBorder,
      visualDensity: VisualDensity.compact,
    );
  }
}
