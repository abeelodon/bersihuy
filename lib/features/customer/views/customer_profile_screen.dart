import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/widgets/customer_bottom_nav.dart';
import '../services/customer_profile_service.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  static const _profileService = CustomerProfileService();

  CustomerProfileOverview? _overview;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final overview = await _profileService.getOverview();
      if (!mounted) return;
      setState(() => _overview = overview);
    } catch (error, stackTrace) {
      debugPrint('CUSTOMER PROFILE LOAD ERROR: $error');
      debugPrint('CUSTOMER PROFILE LOAD STACKTRACE: $stackTrace');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Profil belum dapat dimuat. Silakan coba lagi.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openEditProfile() async {
    await Navigator.pushNamed(context, AppRoutes.customerEditProfile);
    if (mounted) await _loadProfile();
  }

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
              child: Stack(
                children: [
                  ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 104),
                      child: _buildContent(),
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: CustomerBottomNav(currentIndex: 3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 120),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _overview == null) {
      return _buildErrorState();
    }

    final profile = _overview!.profile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildProfileHeaderCard(profile),
        if (!profile.isComplete) ...[
          const SizedBox(height: 16),
          _buildCompletionCard(),
        ],
        const SizedBox(height: 20),
        _buildMembershipCard(),
        const SizedBox(height: 20),
        _buildAccountMenu(),
        const SizedBox(height: 20),
        _buildLogoutButton(),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white.withValues(alpha: 0.92),
      elevation: 0,
      scrolledUnderElevation: 1,
      titleSpacing: 20,
      centerTitle: false,
      automaticallyImplyLeading: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
          height: 1,
        ),
      ),
      title: Image.asset(
        'assets/images/logo_full.png',
        height: 32,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Text('Bersihuy'),
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.customerSettings);
          },
          icon: const Icon(
            Icons.settings_outlined,
            color: AppColors.onSurfaceVariant,
            size: 22,
          ),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            padding: const EdgeInsets.all(8),
          ),
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            _errorMessage ?? 'Profil belum dapat dimuat.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: _loadProfile,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeaderCard(CustomerProfileData profile) {
    final overview = _overview!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    profile.initials,
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      profile.email.isEmpty
                          ? 'Email tidak tersedia'
                          : profile.email,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _softBadge('Pelanggan'),
                  ],
                ),
              ),
              IconButton(
                onPressed: _openEditProfile,
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: AppColors.primary,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.outlineVariant.withValues(alpha: 0.7)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Pesanan', '${overview.totalOrders}'),
              _buildStatItem('Selesai', '${overview.completedOrders}'),
              _buildStatItem('Member', 'Free'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF2C15E).withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF2C15E).withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF1C2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              color: Color(0xFF9A6A00),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lengkapi profil kamu',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tambahkan nomor WhatsApp dan alamat utama agar pemesanan lebih mudah.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 12.5,
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _openEditProfile,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Lengkapi Sekarang'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF7F5), Color(0xFFD7F2EF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF247D78).withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: -24,
            child: Icon(
              Icons.stars_rounded,
              size: 96,
              color: AppColors.primary.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.stars_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Bersihuy+',
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  _softBadge('Tidak Aktif'),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Langganan rutin, prioritas jadwal, dan promo khusus member.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.bersihuyPlus);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                ),
                child: Text(
                  'Lihat Benefit',
                  style: AppTextStyles.buttonLabel.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountMenu() {
    return Container(
      decoration: _cardDecoration(radius: 22),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.person_outline,
            title: 'Data Pribadi',
            onTap: _openEditProfile,
          ),
          _divider(),
          _buildMenuItem(
            icon: Icons.payments_outlined,
            title: 'Riwayat Pembayaran',
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.paymentHistory);
            },
          ),
          _divider(),
          _buildMenuItem(
            icon: Icons.support_agent_outlined,
            title: 'Bantuan & Keluhan',
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.helpComplaint);
            },
          ),
          _divider(),
          _buildMenuItem(
            icon: Icons.settings_outlined,
            title: 'Pengaturan',
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.customerSettings);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
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

  Widget _buildLogoutButton() {
    return OutlinedButton.icon(
      onPressed: () async {
        await SupabaseService.signOut();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
            (route) => false,
          );
        }
      },
      icon: const Icon(Icons.logout, size: 18),
      label: const Text('Keluar'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        backgroundColor: AppColors.error.withValues(alpha: 0.035),
        side: BorderSide(
          color: AppColors.error.withValues(alpha: 0.22),
          width: 1.4,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.labelSmall.copyWith(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: AppColors.outline,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _softBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
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
