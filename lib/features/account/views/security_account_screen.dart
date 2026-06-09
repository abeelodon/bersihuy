import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';

class SecurityAccountScreen extends StatelessWidget {
  const SecurityAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _premiumAppBar(context, 'Keamanan Akun'),
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
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildStatusCard(),
                                const SizedBox(height: 16),
                                _buildLoginMethodCard(),
                                const SizedBox(height: 16),
                                _buildMenuCard(context),
                                const Spacer(),
                                const SizedBox(height: 20),
                                _buildFooterNote(),
                              ],
                            ),
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

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(radius: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppColors.primary,
              size: 30,
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
                        'Status Keamanan',
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
                  'Akun kamu terlindungi dengan email, password, dan opsi login Google.',
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

  Widget _buildLoginMethodCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metode Login',
            style: AppTextStyles.headlineSmall.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          _loginMethodRow(
            icon: Icons.mail_outline,
            title: 'Email & Password',
            status: 'Aktif',
          ),
          _divider(),
          _loginMethodRow(
            icon: Icons.g_mobiledata,
            title: 'Google Login',
            status: 'Terhubung',
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context) {
    final items = [
      _SecurityMenuItem(
        icon: Icons.lock_reset,
        label: 'Ubah Password',
        route: AppRoutes.changePassword,
      ),
      _SecurityMenuItem(
        icon: Icons.manage_accounts_outlined,
        label: 'Kelola Login Google',
        route: AppRoutes.googleLogin,
      ),
      _SecurityMenuItem(
        icon: Icons.history,
        label: 'Aktivitas Login',
        route: AppRoutes.loginActivity,
      ),
      _SecurityMenuItem(
        icon: Icons.devices_outlined,
        label: 'Perangkat Terhubung',
        route: AppRoutes.connectedDevices,
      ),
    ];

    return Container(
      decoration: _cardDecoration(radius: 24),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _menuRow(context, items[i]),
            if (i != items.length - 1) _divider(horizontal: 18),
          ],
        ],
      ),
    );
  }

  Widget _loginMethodRow({
    required IconData icon,
    required String title,
    required String status,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _statusBadge(status),
      ],
    );
  }

  Widget _menuRow(BuildContext context, _SecurityMenuItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, item.route),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.075),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.outline,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footerIcon() {
    return const Icon(Icons.info_outline, color: AppColors.primary, size: 18);
  }

  Widget _buildFooterNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          _footerIcon(),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Jangan bagikan password atau kode login kepada siapa pun.',
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

  Widget _divider({double horizontal = 0}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 12),
      child: Divider(
        height: 1,
        color: AppColors.outlineVariant.withValues(alpha: 0.6),
      ),
    );
  }
}

class _SecurityMenuItem {
  final IconData icon;
  final String label;
  final String route;

  const _SecurityMenuItem({
    required this.icon,
    required this.label,
    required this.route,
  });
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
