import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/staff_premium_widgets.dart';
import '../repositories/staff_task_repository.dart';

class StaffProfileScreen extends StatefulWidget {
  const StaffProfileScreen({super.key});

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen> {
  static const _repository = StaffTaskRepository();

  StaffProfileOverview? _overview;
  bool _isLoadingProfile = true;
  String? _profileError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoadingProfile = true;
      _profileError = null;
    });

    try {
      final overview = await _repository.getStaffProfileOverview();
      if (!mounted) return;
      setState(() => _overview = overview);
    } catch (error, stackTrace) {
      debugPrint('STAFF PROFILE SCREEN LOAD ERROR: $error');
      debugPrint('STAFF PROFILE SCREEN LOAD STACKTRACE: $stackTrace');
      if (!mounted) return;
      setState(() {
        _profileError = 'Profil petugas belum dapat dimuat. Silakan coba lagi.';
      });
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _openEditProfile() async {
    await Navigator.pushNamed(context, AppRoutes.staffEditProfile);
    if (mounted) await _loadProfile();
  }

  StaffOperationalProfile? get _profile => _overview?.profile;
  StaffProfileStats get _stats => _overview?.stats ?? StaffProfileStats.empty;
  String get _name => _profile?.fullName ?? 'Petugas Bersihuy';
  String get _email => _profile?.email ?? '-';
  String get _initials => _profile?.initials ?? 'P';
  String get _workSchedule => _profile?.workSchedule ?? 'Jadwal belum diatur';
  String get _serviceArea => _profile?.serviceArea ?? 'Area belum diatur';
  String get _phone => _profile?.phone ?? 'Telepon belum diatur';
  String get _baseLocation => _profile?.baseLocation ?? 'Base belum diatur';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 20,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Image.asset(
          'assets/images/logo_full.png',
          height: 32,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Text(
            'Bersihuy',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () {
                    showStaffInfoSnackBar(
                      context,
                      'Notifikasi petugas segera hadir (dummy).',
                    );
                  },
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.onSurfaceVariant,
                    size: 24,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.outlineVariant.withValues(
                      alpha: 0.2,
                    ),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '1',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
            height: 1,
          ),
        ),
      ),
      body: PremiumStaffBackground(
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
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 128),
                      child: _buildProfileContent(context),
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: StaffBottomNav(currentIndex: 3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context) {
    if (_isLoadingProfile) {
      return const Padding(
        padding: EdgeInsets.only(top: 140),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_profileError != null) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: _cardDecoration(radius: 22),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              _profileError!,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildProfileHeaderCard(context),
        const SizedBox(height: 18),
        _buildStatGrid(),
        const SizedBox(height: 18),
        _buildScheduleCard(),
        const SizedBox(height: 18),
        _buildMenuSection(context),
        const SizedBox(height: 18),
        _buildSupportSection(context),
        const SizedBox(height: 18),
        _buildLogoutButton(context),
      ],
    );
  }

  // ─── Profile Header Card ──────────────────────────────────────────────────

  Widget _buildProfileHeaderCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.16),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    _isLoadingProfile ? '...' : _initials,
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name,
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _email,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _softBadge('Petugas', AppColors.primary),
                        const SizedBox(width: 6),
                        _softBadge('Siap Bertugas', const Color(0xFF2F7D54)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _openEditProfile,
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: AppColors.primary,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            color: AppColors.outlineVariant.withValues(alpha: 0.6),
            height: 1,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _headerStatItem('${_stats.completedTasks}', 'Tugas Selesai'),
              _headerStatItem(
                _stats.averageRating?.toStringAsFixed(1) ?? '-',
                'Rating',
              ),
              _headerStatItem('${_stats.tasksThisMonth}', 'Bulan Ini'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headlineSmall.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: AppTextStyles.labelSmall.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: AppColors.outline,
          ),
        ),
      ],
    );
  }

  Widget _softBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  // ─── Stat Grid ─────────────────────────────────────────────────────────────

  Widget _buildStatGrid() {
    final stats = [
      (
        icon: Icons.check_circle_rounded,
        label: 'Tugas Selesai',
        value: '${_stats.completedTasks}',
        color: const Color(0xFF2F7D54),
        bg: const Color(0xFFEAF8EF),
        borderColor: const Color(0xFF8FD7AA).withValues(alpha: 0.36),
      ),
      (
        icon: Icons.star_rounded,
        label: 'Rating',
        value: _stats.averageRating?.toStringAsFixed(1) ?? 'Belum ada',
        color: const Color(0xFFF59E0B),
        bg: const Color(0xFFFFF8DF),
        borderColor: const Color(0xFFF2C15E).withValues(alpha: 0.36),
      ),
      (
        icon: Icons.report_rounded,
        label: 'Komplain',
        value: '${_stats.complaintCount}',
        color: AppColors.error,
        bg: const Color(0xFFFFE8E8),
        borderColor: const Color(0xFFE89090).withValues(alpha: 0.36),
      ),
      (
        icon: Icons.calendar_month_rounded,
        label: 'Bulan Ini',
        value: '${_stats.tasksThisMonth}',
        color: const Color(0xFF2B6577),
        bg: const Color(0xFFE8F2FB),
        borderColor: const Color(0xFFB3D4EE).withValues(alpha: 0.36),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: stats.map((s) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: s.bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: s.borderColor),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF247D78).withValues(alpha: 0.045),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: s.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(s.icon, color: s.color, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                s.value,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: s.color,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                s.label,
                style: AppTextStyles.labelSmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── Schedule Card ─────────────────────────────────────────────────────────

  Widget _buildScheduleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Jadwal & Area Hari Ini',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(
            color: AppColors.outlineVariant.withValues(alpha: 0.5),
            height: 1,
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              _scheduleItem(
                icon: Icons.access_time_rounded,
                label: 'Jadwal',
                value: _workSchedule,
                color: const Color(0xFF2B6577),
                bg: const Color(0xFFE8F2FB),
              ),
              const SizedBox(width: 12),
              _scheduleItem(
                icon: Icons.map_outlined,
                label: 'Area',
                value: _serviceArea,
                color: AppColors.primary,
                bg: AppColors.primarySoft,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _scheduleItem(
                icon: Icons.phone_outlined,
                label: 'Telepon',
                value: _phone,
                color: const Color(0xFF2F7D54),
                bg: const Color(0xFFEAF8EF),
              ),
              const SizedBox(width: 12),
              _scheduleItem(
                icon: Icons.home_work_outlined,
                label: 'Lokasi Base',
                value: _baseLocation,
                color: const Color(0xFFD97706),
                bg: const Color(0xFFFFF7E8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scheduleItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bg,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Menu Section ──────────────────────────────────────────────────────────

  Widget _buildMenuSection(BuildContext context) {
    final items = [
      (Icons.person_outlined, 'Data Pribadi', AppRoutes.staffEditProfile),
      (Icons.schedule_outlined, 'Jadwal Kerja', AppRoutes.staffSchedule),
      (Icons.map_outlined, 'Area Layanan', AppRoutes.staffServiceArea),
      (
        Icons.confirmation_number_outlined,
        'Kode Promo Petugas',
        AppRoutes.staffReferral,
      ),
    ];

    return Container(
      decoration: _cardDecoration(radius: 22),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final (icon, label, route) = entry.value;
          final isLast = i == items.length - 1;

          return Column(
            children: [
              InkWell(
                onTap: route == AppRoutes.staffEditProfile
                    ? _openEditProfile
                    : () => Navigator.pushNamed(context, route),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
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
                          label,
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
              ),
              if (!isLast)
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: AppColors.outlineVariant.withValues(alpha: 0.28),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ─── Support Section ───────────────────────────────────────────────────────

  Widget _buildSupportSection(BuildContext context) {
    return Container(
      decoration: _cardDecoration(radius: 22),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _supportItem(
            icon: Icons.help_center_outlined,
            label: 'Bantuan & Keluhan',
            onTap: () => Navigator.pushNamed(context, AppRoutes.staffHelp),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: AppColors.outlineVariant.withValues(alpha: 0.28),
          ),
          _supportItem(
            icon: Icons.settings_outlined,
            label: 'Pengaturan',
            onTap: () => Navigator.pushNamed(context, AppRoutes.staffSettings),
          ),
        ],
      ),
    );
  }

  Widget _supportItem({
    required IconData icon,
    required String label,
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
                label,
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

  // ─── Logout Button ─────────────────────────────────────────────────────────

  Widget _buildLogoutButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => confirmStaffLogout(context),
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

  // ─── Card Decoration ───────────────────────────────────────────────────────

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
