import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';

class CustomerSettingsScreen extends StatefulWidget {
  const CustomerSettingsScreen({super.key});

  @override
  State<CustomerSettingsScreen> createState() => _CustomerSettingsScreenState();
}

class _CustomerSettingsScreenState extends State<CustomerSettingsScreen> {
  bool _notifOrders = true;
  bool _notifPromo = false;
  bool _notifSchedule = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _PremiumCustomerBackground(
        child: SafeArea(
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 460),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _section('Keamanan', [
                        _row(
                          icon: Icons.shield_outlined,
                          title: 'Keamanan Akun',
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.securityAccount,
                            );
                          },
                        ),
                      ]),
                      const SizedBox(height: 20),
                      _section('Notifikasi', [
                        _switchRow(
                          icon: Icons.notifications_none_outlined,
                          title: 'Notifikasi Pesanan',
                          value: _notifOrders,
                          onChanged: (value) {
                            setState(() => _notifOrders = value);
                          },
                        ),
                        _divider(),
                        _switchRow(
                          icon: Icons.campaign_outlined,
                          title: 'Notifikasi Promo',
                          value: _notifPromo,
                          onChanged: (value) {
                            setState(() => _notifPromo = value);
                          },
                        ),
                        _divider(),
                        _switchRow(
                          icon: Icons.event_note_outlined,
                          title: 'Pengingat Jadwal',
                          value: _notifSchedule,
                          onChanged: (value) {
                            setState(() => _notifSchedule = value);
                          },
                        ),
                      ]),
                      const SizedBox(height: 20),
                      _section('Preferensi Aplikasi', [
                        _row(
                          icon: Icons.language_outlined,
                          title: 'Bahasa',
                          trailingText: 'Indonesia',
                          onTap: _dummySnack,
                        ),
                        _divider(),
                        _row(
                          icon: Icons.palette_outlined,
                          title: 'Tema',
                          trailingText: 'Sistem Default',
                          onTap: _dummySnack,
                        ),
                      ]),
                      const SizedBox(height: 20),
                      _section('Informasi Lainnya', [
                        _row(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Kebijakan Privasi',
                          onTap: _dummySnack,
                        ),
                        _divider(),
                        _row(
                          icon: Icons.description_outlined,
                          title: 'Syarat & Ketentuan',
                          onTap: _dummySnack,
                        ),
                      ]),
                      const SizedBox(height: 24),
                      _dangerButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white.withValues(alpha: 0.92),
      elevation: 0,
      scrolledUnderElevation: 1,
      titleSpacing: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Pengaturan',
        style: AppTextStyles.headlineSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
          height: 1,
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.outline,
            ),
          ),
        ),
        Container(
          decoration: _cardDecoration(radius: 22),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _row({
    required IconData icon,
    required String title,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            _iconBubble(icon, active: false),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.outline,
                ),
              ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right,
              color: AppColors.outlineVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchRow({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          _iconBubble(icon, active: value),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.outlineVariant,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _dangerButton() {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.deleteAccount);
      },
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.035),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_forever_outlined,
                color: AppColors.error,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Hapus Akun',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBubble(IconData icon, {required bool active}) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: (active ? AppColors.primary : AppColors.outline).withValues(
          alpha: active ? 0.1 : 0.08,
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: active ? AppColors.primary : AppColors.onSurfaceVariant,
        size: 18,
      ),
    );
  }

  void _dummySnack() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Fitur ini masih dummy.')));
  }

  Widget _divider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.outlineVariant.withValues(alpha: 0.28),
    );
  }

  BoxDecoration _cardDecoration({required double radius}) {
    return BoxDecoration(
      color: const Color(0xFFFEFFFF),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: AppColors.outlineVariant.withValues(alpha: 0.72),
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF247D78).withValues(alpha: 0.055),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}

class _PremiumCustomerBackground extends StatelessWidget {
  final Widget child;

  const _PremiumCustomerBackground({required this.child});

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
