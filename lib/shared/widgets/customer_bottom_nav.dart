import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';

class CustomerBottomNav extends StatelessWidget {
  final int currentIndex;

  const CustomerBottomNav({super.key, required this.currentIndex});

  static const _items = [
    _BottomNavItem('Beranda', Icons.home, Icons.home_outlined),
    _BottomNavItem('Layanan', Icons.grid_view, Icons.grid_view_outlined),
    _BottomNavItem('Pesanan', Icons.assignment, Icons.assignment_outlined),
    _BottomNavItem('Profil', Icons.person, Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF247D78).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: const Color(0xFFDDE8E6).withValues(alpha: 0.72),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (index) {
          final item = _items[index];
          final isSelected = index == currentIndex;
          final color = isSelected ? AppColors.primary : AppColors.outline;

          return GestureDetector(
            onTap: () => _handleTap(context, index),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 68,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 36,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      isSelected ? item.activeIcon : item.inactiveIcon,
                      color: color,
                      size: 21,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall.copyWith(
                      fontSize: 10.5,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  void _handleTap(BuildContext context, int index) {
    if (index == currentIndex) {
      return;
    }

    final route = switch (index) {
      0 => AppRoutes.customerHome,
      1 => AppRoutes.customerServices,
      2 => AppRoutes.customerOrders,
      _ => AppRoutes.customerProfile,
    };
    Navigator.pushReplacementNamed(context, route);
  }
}

class _BottomNavItem {
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;

  const _BottomNavItem(this.label, this.activeIcon, this.inactiveIcon);
}
