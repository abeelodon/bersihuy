import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/supabase_service.dart';

class PremiumStaffBackground extends StatelessWidget {
  final Widget child;

  const PremiumStaffBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8FAFB), Color(0xFFF4FAF9), Color(0xFFEEF8F7)],
            ),
          ),
          child: SizedBox.expand(),
        ),
        child,
      ],
    );
  }
}

class StaffBottomNav extends StatelessWidget {
  final int currentIndex;

  const StaffBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StaffNavItem(
        label: 'Beranda',
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        route: AppRoutes.staffHome,
      ),
      _StaffNavItem(
        label: 'Tugas',
        icon: Icons.assignment_outlined,
        activeIcon: Icons.assignment,
        route: AppRoutes.staffTasks,
      ),
      _StaffNavItem(
        label: 'Riwayat',
        icon: Icons.history,
        activeIcon: Icons.history,
        route: AppRoutes.staffHistory,
      ),
      _StaffNavItem(
        label: 'Profil',
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        route: AppRoutes.staffProfile,
      ),
    ];

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
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isActive = currentIndex == index;
          final color = isActive ? AppColors.primary : AppColors.outline;

          return GestureDetector(
            onTap: () {
              if (!isActive) {
                Navigator.pushReplacementNamed(context, item.route);
              }
            },
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
                      color: isActive
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      isActive ? item.activeIcon : item.icon,
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
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
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
}

class StaffStatusBadge extends StatelessWidget {
  final String label;

  const StaffStatusBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final (textColor, backgroundColor) = _colorsFor(label);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.labelSmall.copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }

  (Color, Color) _colorsFor(String status) {
    if (status == 'Ditugaskan' || status == 'Dalam Perjalanan') {
      return (
        const Color(0xFF2B6577),
        const Color(0xFFCFE2F9).withValues(alpha: 0.58),
      );
    }
    if (status == 'Selesai' || status == 'Diulas') {
      return (const Color(0xFF2F7D54), const Color(0xFFE4F7EC));
    }
    if (status == 'Menunggu') {
      return (const Color(0xFF9A650F), const Color(0xFFFFF1D6));
    }
    if (status == 'Komplain') {
      return (AppColors.error, AppColors.error.withValues(alpha: 0.08));
    }
    return (AppColors.primary, AppColors.primary.withValues(alpha: 0.1));
  }
}

BoxDecoration staffPremiumCardDecoration({
  Color color = Colors.white,
  double radius = 22,
  Color? borderColor,
  double shadowOpacity = 0.07,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: borderColor ?? AppColors.outlineVariant.withValues(alpha: 0.42),
    ),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF247D78).withValues(alpha: shadowOpacity),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

Widget staffSoftIcon({
  required IconData icon,
  Color color = AppColors.primary,
  double size = 42,
}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, color: color, size: size * 0.48),
  );
}

void showStaffInfoSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: AppTextStyles.bodyMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: const Color(0xFF173B3A),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

Future<void> confirmStaffLogout(BuildContext context) async {
  final shouldLogout = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Keluar akun?',
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        content: Text(
          'Kamu akan kembali ke halaman login.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Batal',
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Keluar',
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    },
  );

  if (shouldLogout == true && context.mounted) {
    await SupabaseService.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }
}

class _StaffNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const _StaffNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}
