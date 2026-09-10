import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class AnimatedTabBar extends StatelessWidget {
  final TabController controller;
  final List<AnimatedTab> tabs;
  final Color? labelColor;
  final Color? unselectedLabelColor;
  final Color? indicatorColor;

  const AnimatedTabBar({
    Key? key,
    required this.controller,
    required this.tabs,
    this.labelColor,
    this.unselectedLabelColor,
    this.indicatorColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: tabs.asMap().entries.map((entry) {
              final index = entry.key;
              final tab = entry.value;
              final isSelected = controller.index == index;

              return _buildTab(
                context,
                tab: tab,
                isSelected: isSelected,
                onTap: () {
                  controller.animateTo(index);
                },
                isDark: isDark,
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildTab(
      BuildContext context, {
        required AnimatedTab tab,
        required bool isSelected,
        required VoidCallback onTap,
        required bool isDark,
      }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (indicatorColor ?? AppColors.primaryLight)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono
            Icon(
              tab.icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : (unselectedLabelColor ??
                  (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary)),
            ),
            // Texto que aparece solo cuando está seleccionado
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              child: isSelected
                  ? Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  tab.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: labelColor ?? Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedTab {
  final IconData icon;
  final String label;

  const AnimatedTab({
    required this.icon,
    required this.label,
  });
}