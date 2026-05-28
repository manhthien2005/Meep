import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';

// TODO: replace with SvgPicture.asset() when SVG assets are added
// grid-3x3 → assets/icons/ic_grid_3x3.svg
// book-heart → assets/icons/ic_book_heart.svg
const _cInactiveIcon = Color(0xFF949494); // TODO: add AppColors.tabIconInactive

class ProfileTabBar extends StatelessWidget {
  const ProfileTabBar({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
  });

  final int activeTab;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _TabItem(
                icon: Icons.grid_view_rounded,
                isActive: activeTab == 0,
                semanticsLabel: 'Tab ảnh',
                onTap: () => onTabChanged(0),
              ),
            ),
            Expanded(
              child: _TabItem(
                icon: Icons.menu_book_rounded,
                isActive: activeTab == 1,
                semanticsLabel: 'Tab nhật ký',
                onTap: () => onTabChanged(1),
              ),
            ),
          ],
        ),
        Stack(
          children: [
            Container(height: 1, color: AppColors.bw300.withOpacity(0.5)),
            AnimatedAlign(
              alignment:
                  activeTab == 0 ? Alignment.centerLeft : Alignment.centerRight,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(height: 1, color: AppColors.bw100),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.isActive,
    required this.semanticsLabel,
    required this.onTap,
  });

  final IconData icon;
  final bool isActive;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isActive,
      label: semanticsLabel,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 33,
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: isActive ? AppColors.bw100 : _cInactiveIcon,
            ),
          ),
        ),
      ),
    );
  }
}
