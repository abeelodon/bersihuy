import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class CustomerNotificationScreen extends StatelessWidget {
  const CustomerNotificationScreen({super.key});

  static const _notifications = [
    _NotificationItem(
      icon: Icons.cleaning_services_outlined,
      title: 'Pesanan Diproses',
      subtitle: 'Pesanan Deep Cleaning sedang dalam proses.',
      timestamp: 'Baru saja',
    ),
    _NotificationItem(
      icon: Icons.stars_rounded,
      title: 'Promo Member',
      subtitle: 'Promo Bersihuy+ aktif minggu ini.',
      timestamp: '1 jam lalu',
    ),
    _NotificationItem(
      icon: Icons.spa_outlined,
      title: 'Produk Tersedia',
      subtitle: 'Refill Fresh Linen tersedia untuk pembelian.',
      timestamp: 'Hari ini',
    ),
    _NotificationItem(
      icon: Icons.event_available_outlined,
      title: 'Jadwal Hari Ini',
      subtitle: 'Jadwal Bersih Rumah kamu akan dimulai hari ini pukul 14.00.',
      timestamp: 'Hari ini',
    ),
    _NotificationItem(
      icon: Icons.yard_outlined,
      title: 'Layanan Khusus',
      subtitle: 'Pest Control Outdoor tersedia untuk area rumah dan kos.',
      timestamp: 'Kemarin',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF172331)),
        ),
        title: Text(
          'Notifikasi',
          style: AppTextStyles.headlineSmall.copyWith(
            color: const Color(0xFF142232),
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
            height: 1,
          ),
        ),
      ),
      body: _PremiumNotificationBackground(
        child: SafeArea(
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 460),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
                itemCount: _notifications.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _NotificationCard(item: _notifications[index]);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final _NotificationItem item;

  const _NotificationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDDE8E6).withValues(alpha: 0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF247D78).withValues(alpha: 0.055),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F7F5),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: const Color(0xFF2F8F8A), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: AppTextStyles.labelMedium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF172331),
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      item.timestamp,
                      style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 10.5,
                        color: const Color(0xFF7A8988),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  item.subtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 13,
                    color: const Color(0xFF65737D),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumNotificationBackground extends StatelessWidget {
  final Widget child;

  const _PremiumNotificationBackground({required this.child});

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

class _NotificationItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String timestamp;

  const _NotificationItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.timestamp,
  });
}
