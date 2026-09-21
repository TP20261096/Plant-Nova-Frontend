import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        bottom: true,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                index: 0,
                isDark: isDark,
              ),
              _buildNavItem(
                icon: Icons.menu_book_outlined,
                activeIcon: Icons.menu_book,
                index: 1,
                isDark: isDark,
              ),
              _buildAnalyzeButton(isDark),
              _buildNavItem(
                icon: Icons.local_florist_outlined,
                activeIcon: Icons.local_florist,
                index: 3,
                isDark: isDark,
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                index: 4,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required int index,
    required bool isDark,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected
        ? AppColors.primaryLight
        : isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            child: Icon(
              isSelected ? activeIcon : icon,
              color: color,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton(bool isDark) {
    final isSelected = currentIndex == 2;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(2),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isSelected
                    ? [AppColors.primaryLight, AppColors.primary]
                    : [AppColors.primary, AppColors.primaryLight],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}