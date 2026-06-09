import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';

class LoginActivityScreen extends StatelessWidget {
  const LoginActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _premiumAppBar(context, 'Aktivitas Login'),
      body: _PremiumAccountBackground(
        child: SafeArea(
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 460),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildSummaryCard(),
                              const SizedBox(height: 20),
                              _sectionLabel('Aktivitas Login Terbaru'),
                              const SizedBox(height: 12),
                              _activityCard(
                                icon: Icons.laptop_mac_outlined,
                                title: 'Chrome di Windows',
                                time: 'Hari ini, 09.30',
                                location: 'Indonesia',
                                method: 'Email & Password',
                                status: 'Berhasil',
                                currentDevice: true,
                              ),
                              const SizedBox(height: 12),
                              _activityCard(
                                icon: Icons.g_mobiledata,
                                title: 'Google Login',
                                time: '25 Mei 2026, 21.10',
                                location: 'Indonesia',
                                method: 'Google',
                                status: 'Berhasil',
                              ),
                              const SizedBox(height: 12),
                              _activityCard(
                                icon: Icons.phone_android_outlined,
                                title: 'Android App',
                                time: '24 Mei 2026, 14.45',
                                location: 'Indonesia',
                                method: 'Email & Password',
                                status: 'Berhasil',
                              ),
                              const SizedBox(height: 18),
                              _buildInfoNote(),
                              const SizedBox(height: 16),
                              _buildChangePasswordButton(context),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(radius: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Aktivitas Login Terbaru',
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    _statusBadge('Aman'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Pantau riwayat login akun kamu untuk menjaga keamanan.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityCard({
    required IconData icon,
    required String title,
    required String time,
    required String location,
    required String method,
    required String status,
    bool currentDevice = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (currentDevice) _softBadge('Perangkat ini'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.outline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _meta('Lokasi', location)),
              Expanded(child: _meta('Metode', method)),
              _meta('Status', status, alignEnd: true, primary: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Jika kamu melihat aktivitas mencurigakan, segera ubah password akunmu.',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangePasswordButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => Navigator.pushNamed(context, AppRoutes.changePassword),
      icon: const Icon(Icons.lock_reset, size: 18),
      label: Text(
        'Ubah Password',
        style: AppTextStyles.buttonLabel.copyWith(fontWeight: FontWeight.w800),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.labelMedium.copyWith(
        color: AppColors.onSurface,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _meta(
    String label,
    String value, {
    bool alignEnd = false,
    bool primary = false,
  }) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.outline,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style: AppTextStyles.labelMedium.copyWith(
            color: primary ? AppColors.primary : AppColors.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _softBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

PreferredSizeWidget _premiumAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: Colors.white.withValues(alpha: 0.92),
    elevation: 0,
    scrolledUnderElevation: 1,
    centerTitle: false,
    titleSpacing: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: AppColors.primary),
      onPressed: () => Navigator.pop(context),
    ),
    title: Text(
      title,
      style: AppTextStyles.headlineSmall.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w800,
      ),
    ),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(
        height: 1,
        color: AppColors.outlineVariant.withValues(alpha: 0.3),
      ),
    ),
  );
}

BoxDecoration _cardDecoration({required double radius}) {
  return BoxDecoration(
    color: const Color(0xFFFEFFFF),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.72)),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF247D78).withValues(alpha: 0.055),
        blurRadius: 22,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

class _PremiumAccountBackground extends StatelessWidget {
  final Widget child;

  const _PremiumAccountBackground({required this.child});

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
